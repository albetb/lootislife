extends Node

'''
 Events.signal_name.connect(self._on_signal_name) # To subscribe
 Events.emit_signal("signal_name") # To emit
'''


signal update_ui
signal choice_selected(number: int)
