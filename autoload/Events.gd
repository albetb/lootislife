extends Node

'''
 Events.signal_name.connect(self._on_signal_name) # To subscribe
 Events.emit_signal("signal_name") # To emit
'''

signal update_ui
signal choice_selected(number: int)
signal inventory_changed()
signal request_move_item(item: InventoryItemData, target_cell: Vector2i)
signal request_equip_item(item: InventoryItemData, slot: EquipmentSlot)
signal request_unequip_item(item: InventoryItemData, target_cell: Vector2i)

signal treasure_loot_requested(equipment: Array[EquipmentData])
