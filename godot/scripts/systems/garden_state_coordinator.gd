class_name GardenStateCoordinator
extends Node

var chart: StateChart
var active_states := {
	&"player": &"idle",
	&"tool": &"ready",
	&"weather": &"clear",
	&"menu": &"gameplay",
}


func build() -> void:
	chart = StateChart.new()
	chart.name = "GardenStateChart"
	chart.warn_on_sending_unknown_events = false
	var parallel := ParallelState.new()
	parallel.name = "GardenSystems"
	chart.add_child(parallel)
	_create_domain(parallel, "Player", [&"idle", &"moving", &"crouched"])
	_create_domain(parallel, "Tool", [&"ready", &"swinging", &"maintenance"])
	_create_domain(parallel, "Weather", [&"clear", &"rain"])
	_create_domain(parallel, "Menu", [&"gameplay", &"paused", &"journal"])
	add_child(chart)
	chart.event_received.connect(_on_chart_event)


func send_domain_event(domain: StringName, state: StringName) -> void:
	if not active_states.has(domain) or active_states[domain] == state:
		return
	active_states[domain] = state
	if chart != null:
		chart.send_event("%s_%s" % [domain, state])


func state_snapshot() -> Dictionary:
	return active_states.duplicate()


func _create_domain(parent: ParallelState, title: String, states: Array[StringName]) -> void:
	var compound := CompoundState.new()
	compound.name = title
	parent.add_child(compound)
	for state_name in states:
		var atomic := AtomicState.new()
		atomic.name = _pascal_case(String(state_name))
		compound.add_child(atomic)
	compound.initial_state = NodePath(_pascal_case(String(states[0])))
	for source_state in states:
		var source := compound.get_node(_pascal_case(String(source_state))) as AtomicState
		for target_state in states:
			if target_state == source_state:
				continue
			var transition := Transition.new()
			transition.name = "To%s" % _pascal_case(String(target_state))
			transition.event = "%s_%s" % [title.to_snake_case(), target_state]
			transition.to = NodePath("../../%s" % _pascal_case(String(target_state)))
			source.add_child(transition)


func _on_chart_event(_event: StringName) -> void:
	pass


func _pascal_case(value: String) -> String:
	return value.capitalize().replace(" ", "")
