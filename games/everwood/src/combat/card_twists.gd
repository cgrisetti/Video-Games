## The Ink Card Deck's twists (25_GRIMOIRE_GEAR_LEVELING_AND_MENUS_OVERHAUL.md §7):
## the one rule each of the eight deck cards has that no other card does. The
## hero's SignFlowComponent calls in here while the card's coat or shield is up:
##   on a coated hit     Cairn-Cleave rings a big foe on every third hit (SHATTERPOINT
##                       for a friend's Heavy); Squall-Lash frost-slows and bursts in
##                       GLACIAL RUPTURE on the fourth; Ember-Wick Cut stacks an
##                       Ember-Burn that wears stagger down faster; Tide-Turn Thrust
##                       gives the hero Breath back
##   on a counter-brace  Hedge-Root Brace roots the foe that swung; Hoarfrost Mantle
##                       breathes out a frost ring that slows every foe in it;
##                       Kindle-Hearth Ward sets off DAWNBURST (the party mends);
##                       Moon-Weir Guard gives friends behind the hero Breath
##   while it's up       Kindle-Hearth Ward mends friends sheltering behind the hero;
##                       Moon-Weir Guard turns a Perfect Guard into an Ink-Drop;
##                       Hoarfrost Mantle shrugs off every slow
## The numbers live here, one place to tune them.
class_name CardTwists
extends RefCounted

enum Twist { NONE, RING_EVERY_THIRD, SQUALL_LASH, EMBER_BURN, TIDE_BREATH, ROOT_COUNTER, FROST_RING_COUNTER, HEARTH_MEND, MOON_WEIR }

## Cairn-Cleave: every this-many coated hits on one foe rings it with the coat's Sign.
const RING_EVERY: int = 3
## Squall-Lash: each coated hit slows the foe this much for this long; every fourth bursts.
const FROST_SLOW: float = 0.2
const FROST_SLOW_SECONDS: float = 2.0
const FROST_BURST_EVERY: int = 4
## Ember-Wick Cut: each stack wears the foe's stagger down this much faster, up to this many.
const EMBER_PER_STACK: float = 0.18
const EMBER_MAX_STACKS: int = 3
## Tide-Turn Thrust: Breath back on each coated hit.
const TIDE_BREATH: float = 6.0
## Hedge-Root Brace: the counter-brace roots the foe that swung (a full slow) this long.
const ROOT_SECONDS: float = 1.5
## How far the counter-brace looks for that foe when it can't name it.
const COUNTER_REACH: float = 3.5
## Hoarfrost Mantle: the counter-brace's frost ring.
const FROST_RING_RADIUS: float = 4.0
const FROST_RING_SLOW: float = 0.4
const FROST_RING_SECONDS: float = 3.0
## Kindle-Hearth Ward: friends this close behind the hero mend this share of their health a second.
const MEND_RADIUS: float = 3.0
const MEND_SHARE: float = 0.015
## Moon-Weir Guard: a Perfect Guard pours this many Ink-Drops, at most once in this long;
## the counter-brace gives friends behind the hero this much Breath.
const WEIR_INK: float = 1.0
const WEIR_COOLDOWN: float = 4.0
const WEIR_BREATH: float = 15.0
const WEIR_RADIUS: float = 4.0
## How far behind the hero "behind" reaches round its back (the dot of facing and the way to a friend).
const BEHIND_DOT: float = 0.2


## A coated hit landed: the coat's card adds its twist to the strike.
static func on_coated_hit(flow: SignFlowComponent, event: CombatEvent) -> void:
	var card: ScribeCardResource = flow.twist_card
	if card == null or card.twist == Twist.NONE:
		return
	var target: ActorBase = flow.actor.get_node_or_null(event.target_path) as ActorBase
	if target == null:
		return
	var key: int = target.get_instance_id()
	var hits: int = int(flow.twist_hits.get(key, 0)) + 1
	flow.twist_hits[key] = hits
	match card.twist:
		Twist.RING_EVERY_THIRD:
			if hits % RING_EVERY == 0 and event.primer == ScribeSignResource.Sign.NONE:
				event.primer = event.coat_sign
		Twist.SQUALL_LASH:
			event.slow_fraction = maxf(event.slow_fraction, FROST_SLOW)
			event.slow_seconds = maxf(event.slow_seconds, FROST_SLOW_SECONDS)
			if hits % FROST_BURST_EVERY == 0:
				CombatDirector.current.sign_detonation(target, event, event.coat_sign, "SQUALL-LASH!")
		Twist.EMBER_BURN:
			var stacks: int = mini(EMBER_MAX_STACKS, int(flow.twist_stacks.get(key, 0)) + 1)
			flow.twist_stacks[key] = stacks
			event.poise_damage *= 1.0 + EMBER_PER_STACK * float(stacks)
		Twist.TIDE_BREATH:
			flow.actor.stats.restore_stamina(TIDE_BREATH)


## L tapped in the flash: the shield's card adds its counter. `card` is the L card just cast.
static func on_counter_brace(flow: SignFlowComponent, card: ScribeCardResource) -> void:
	if card == null:
		return
	var director: CombatDirector = CombatDirector.current
	var actor: ActorBase = flow.actor
	match card.twist:
		Twist.ROOT_COUNTER:
			var swung: ActorBase = flow.last_blocked_attacker()
			if swung == null:
				swung = _nearest_foe(actor, COUNTER_REACH)
			if swung != null:
				director.slow_foe(actor, swung, 1.0, ROOT_SECONDS)
				director.show_float_text(swung.global_position + Vector3.UP * (swung.body_height() + 0.6), "ROOTED!",
					ArsenalCatalog.current.sign_seal(card.scribe_sign).color, 32)
		Twist.FROST_RING_COUNTER:
			for foe: ActorBase in director.enemies():
				if foe.is_targetable() and foe.global_position.distance_to(actor.global_position) <= FROST_RING_RADIUS + foe.body_radius():
					director.slow_foe(actor, foe, FROST_RING_SLOW, FROST_RING_SECONDS)
			director.stamp_sign_ring(actor, card.scribe_sign, FROST_RING_RADIUS)
		Twist.HEARTH_MEND:
			var seal: ScribeSignResource = ArsenalCatalog.current.sign_seal(card.scribe_sign)
			for member: ActorBase in director.alive_party():
				director.apply_heal(actor, member, seal.party_heal)
			director.show_float_text(actor.global_position + Vector3.UP * (actor.body_height() + 0.9), "DAWNBURST!", seal.color, 36)
		Twist.MOON_WEIR:
			for member: ActorBase in friends_behind(actor, WEIR_RADIUS):
				director.reward(member, 0.0, WEIR_BREATH)


## Every frame the shield is up: Kindle-Hearth Ward mends the friends sheltering behind the hero.
static func tick_shield(flow: SignFlowComponent, delta: float) -> void:
	var card: ScribeCardResource = flow.twist_card
	if card == null or card.twist != Twist.HEARTH_MEND or not flow.is_mantled():
		return
	flow.twist_mend_left -= delta
	if flow.twist_mend_left > 0.0:
		return
	flow.twist_mend_left = 1.0
	for member: ActorBase in friends_behind(flow.actor, MEND_RADIUS):
		CombatDirector.current.apply_heal(flow.actor, member, member.stats.stats.max_health * MEND_SHARE)


## A Perfect Guard while Moon-Weir Guard's shield is up pours an Ink-Drop into the well. Returns whether it did.
static func on_perfect_guard(flow: SignFlowComponent) -> bool:
	var card: ScribeCardResource = flow.twist_card
	if card == null or card.twist != Twist.MOON_WEIR or not flow.is_mantled():
		return false
	var now: float = CombatDirector.game_time()
	if now < flow.twist_guard_ready_at:
		return false
	flow.twist_guard_ready_at = now + WEIR_COOLDOWN
	flow.actor.stats.add_ink(WEIR_INK)
	CombatDirector.current.show_float_text(flow.actor.global_position + Vector3.UP * (flow.actor.body_height() + 0.7), "+1 INK-DROP",
		AtelierTheme.INK_DROP, 30)
	return true


## Whether Hoarfrost Mantle's shield is up on this hero, so no slow takes hold.
static func shrugs_slows(actor: ActorBase) -> bool:
	var flow: SignFlowComponent = actor.sign_flow
	return flow != null and flow.twist_card != null and flow.twist_card.twist == Twist.FROST_RING_COUNTER and flow.is_mantled()


## The living party members (not the hero) within `radius` behind the hero's back.
static func friends_behind(actor: ActorBase, radius: float) -> Array[ActorBase]:
	var found: Array[ActorBase] = []
	var facing: Vector3 = -actor.global_basis.z
	facing.y = 0.0
	for member: ActorBase in CombatDirector.current.alive_party():
		if member == actor:
			continue
		var away: Vector3 = member.global_position - actor.global_position
		away.y = 0.0
		if away.length() > radius:
			continue
		if away.length() < 0.5 or facing.normalized().dot(away.normalized()) <= BEHIND_DOT:
			found.append(member)
	return found


static func _nearest_foe(actor: ActorBase, reach: float) -> ActorBase:
	var best: ActorBase = null
	var best_distance: float = reach
	for foe: ActorBase in CombatDirector.current.enemies():
		if not foe.is_targetable():
			continue
		var distance: float = foe.global_position.distance_to(actor.global_position) - foe.body_radius()
		if distance <= best_distance:
			best = foe
			best_distance = distance
	return best
