# lootislife
	
# Godot 4 Design Guidelines

This document summarizes the design practices adopted for our Godot 4 application to keep the code clean, maintainable, and scalable.

---

## 1. Single Responsibility
- **Principle:** Each node is responsible for its own tasks.
- **Usage:** A node may manage its direct children (e.g., for UI updates) to prevent code fragmentation.

---

## 2. Singleton Signal Bus
- **Purpose:** Facilitate communication between nodes via a central signal hub.
- **Implementation:**
  ```
  signal signal_name # In the Events singleton
  Events.signal_name.connect(self._on_signal_name) # To subscribe
  Events.emit_signal("signal_name") # To emit
  ```
---

## 3. Loose Decoupling
- **Guideline:** Avoid direct node references in scripts (except for UI changes for direct children).
- **Tip:** Use the signal bus.
- **Example (Avoid):**
  ```
  @onready var node1 = $"../Path/Node1" # Avoid
  @onready var node2 = $"../Node2" # Ok for ui changes
  ```

---

## 4. Use Resources for Saving
- **Recommendation:** Use Godot resources instead of external file formats (like JSON) for saving data.
- **Usage:**
  ```
  ResourceSaver.save(data, save_file_path)
  ResourceLoader.load(save_file_path, "ResourceName")
  ```

---

## 5. Minimal Node Usage
- **Guideline:** Keep the node tree simple.
- **Tip:** Replace functional nodes with alternatives such as Resource, RefCounted, or Object when possible.

---

## 6. Global Variables
- **Practice:** Update globals via functions rather than modifying values directly.

---

## 7. Using Groups to Retrieve Nodes
- **Usage:** Use groups to fetch nodes efficiently rather than traversing child nodes.
- **Example:**
  ```
  get_tree().get_nodes_in_group("group")
  add_to_group("group")
  ```

---

## 8. Avoid Using Groups to Call Functions
- **Warning:** Do not call functions of other nodes via groups.
- **Tip:** Use the signal bus.
- **Example (Avoid):**
  ```
  get_tree().call_group("group", "func_name") # Avoid
  ```

---

## 9. Scene Management
- **Recommendation:** Use a dedicated SceneManager to switch scenes.
- **Usage:**
  ```
  SceneManager.switch("path")
  ```

---

## 10. Deleting childs
- **Recommendation:** Free the memory allocated for the child with queue_free
- **Usage:**
  ```
  parent.remove_child(child)
  child.queue_free()
  ```

## 11. Separate Game Rules from Presentation
  Rules layer: Cards effects, Status calculations, RNG, Turn system
  Presentation layer: Animations, UI, Card movement
  Rules should run without nodes if possible.
