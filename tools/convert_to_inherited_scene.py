#!/usr/bin/env python3
"""
Converts independent floor scenes to inherited scenes of res://scenes/floors/floor.tscn
"""
import sys
import re

BASE_SCENE_PATH = "res://scenes/floors/floor.tscn"
BASE_SCENE_UID = "uid://dmpsab2hobft3"

PARENT_IDS = {
    "SpawnPoints": 759900,
    "Interactables": 191277635,
    "Enemies": 1020133424,
    "Pickups": 1104918386,
    "Npcs": 1261277173,
    "DynamicTiles": 1459102837,
}

BASE_CONTAINERS = {"SpawnPoints", "Interactables", "Enemies", "Pickups", "Npcs", "DynamicTiles"}

def convert_floor_scene(filepath: str):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    lines = content.splitlines()

    # Find ext_resources and check if base scene is already imported
    ext_resources = []
    has_base_scene = False
    base_res_id = None
    max_res_id = 0

    header_lines = []
    body_lines = []
    in_header = True

    # Parse sections
    sections = []
    current_section = []

    for line in lines:
        if line.startswith("[") and current_section:
            sections.append(current_section)
            current_section = [line]
        else:
            current_section.append(line)
    if current_section:
        sections.append(current_section)

    new_sections = []
    base_res_id = "1_base_floor"

    # Process first section (gd_scene)
    new_sections.append(sections[0])

    # Check if base scene ext_resource exists
    has_base = False
    ext_res_sections = []
    node_sections = []
    sub_res_sections = []

    for sec in sections[1:]:
        header = sec[0]
        if header.startswith("[ext_resource"):
            if BASE_SCENE_PATH in header:
                has_base = True
                m = re.search(r'id="([^"]+)"', header)
                if m:
                    base_res_id = m.group(1)
            ext_res_sections.append(sec)
        elif header.startswith("[sub_resource"):
            sub_res_sections.append(sec)
        elif header.startswith("[node"):
            node_sections.append(sec)

    if not has_base:
        base_res_sec = [f'[ext_resource type="PackedScene" uid="{BASE_SCENE_UID}" path="{BASE_SCENE_PATH}" id="{base_res_id}"]', '']
        new_sections.append(base_res_sec)

    new_sections.extend(ext_res_sections)
    new_sections.extend(sub_res_sections)

    # Now process node sections
    converted_node_sections = []
    child_counts = {k: 0 for k in PARENT_IDS.keys()}

    for sec in node_sections:
        header = sec[0]
        # Match root node
        if header.startswith('[node name="Floor"') or header.startswith('[node name="Floor1"') or header.startswith('[node name="Floor2"') or header.startswith('[node name="Floor3"') or header.startswith('[node name="Floor4"') or header.startswith('[node name="Floor5"'):
            # Convert root node to instance
            m_name = re.search(r'name="([^"]+)"', header)
            name = m_name.group(1) if m_name else "Floor"
            m_uid = re.search(r'unique_id=(\d+)', header)
            uid_str = f" unique_id={m_uid.group(1)}" if m_uid else ""
            new_header = f'[node name="{name}"{uid_str} instance=ExtResource("{base_res_id}")]'
            
            new_sec = [new_header]
            for l in sec[1:]:
                # filter out metadata/_custom_type_script if any
                if l.startswith("metadata/_custom_type_script"):
                    continue
                new_sec.append(l)
            converted_node_sections.append(new_sec)
            continue

        # Match GroundLayer, WallLayer, FeatureLayer
        if header.startswith('[node name="GroundLayer"'):
            m_uid = re.search(r'unique_id=(\d+)', header)
            uid_str = f" unique_id={m_uid.group(1)}" if m_uid else " unique_id=370044564"
            new_header = f'[node name="GroundLayer" parent="." index="0"{uid_str}]'
            new_sec = [new_header]
            for l in sec[1:]:
                if l.startswith("tile_map_data = "):
                    new_sec.append(l)
            new_sec.append('')
            converted_node_sections.append(new_sec)
            continue

        if header.startswith('[node name="WallLayer"'):
            m_uid = re.search(r'unique_id=(\d+)', header)
            uid_str = f" unique_id={m_uid.group(1)}" if m_uid else " unique_id=917837273"
            new_header = f'[node name="WallLayer" parent="." index="1"{uid_str}]'
            new_sec = [new_header]
            for l in sec[1:]:
                if l.startswith("tile_map_data = "):
                    new_sec.append(l)
            new_sec.append('')
            converted_node_sections.append(new_sec)
            continue

        if header.startswith('[node name="FeatureLayer"'):
            m_uid = re.search(r'unique_id=(\d+)', header)
            uid_str = f" unique_id={m_uid.group(1)}" if m_uid else " unique_id=1361208269"
            new_header = f'[node name="FeatureLayer" parent="." index="2"{uid_str}]'
            new_sec = [new_header]
            has_data = False
            for l in sec[1:]:
                if l.startswith("tile_map_data = "):
                    new_sec.append(l)
                    has_data = True
            if has_data:
                new_sec.append('')
                converted_node_sections.append(new_sec)
            continue

        # Check if it is one of the base empty container nodes (e.g. [node name="SpawnPoints" type="Node2D" parent="." ...])
        m_container = re.search(r'\[node name="([^"]+)" type="Node2D" parent="\."', header)
        if m_container and m_container.group(1) in BASE_CONTAINERS:
            # Check if this container has custom non-standard properties (rarely)
            # Typically in base scene they are already defined, so skip empty container declaration
            continue

        # Children of containers (e.g. parent="SpawnPoints", parent="Interactables", etc.)
        m_parent = re.search(r'parent="([^"]+)"', header)
        if m_parent and m_parent.group(1) in PARENT_IDS:
            parent_name = m_parent.group(1)
            p_id = PARENT_IDS[parent_name]
            idx = child_counts[parent_name]
            child_counts[parent_name] += 1

            # Insert parent_id_path and index
            # If already has parent_id_path, remove and update
            clean_header = re.sub(r'parent_id_path=PackedInt32Array\([^)]*\)\s*', '', header)
            clean_header = re.sub(r'index="\d+"\s*', '', clean_header)
            clean_header = clean_header.replace(f'parent="{parent_name}"', f'parent="{parent_name}" parent_id_path=PackedInt32Array({p_id}) index="{idx}"')
            new_sec = [clean_header]
            new_sec.extend(sec[1:])
            converted_node_sections.append(new_sec)
            continue

        # Nested children (e.g. parent="DynamicTiles/WallFirst")
        m_nested = re.search(r'parent="([^"/]+)/([^"]+)"', header)
        if m_nested and m_nested.group(1) in PARENT_IDS:
            root_parent = m_nested.group(1)
            p_id = PARENT_IDS[root_parent]
            clean_header = header
            new_sec = [clean_header]
            new_sec.extend(sec[1:])
            converted_node_sections.append(new_sec)
            continue

        # Other nodes
        converted_node_sections.append(sec)

    new_sections.extend(converted_node_sections)

    # Reconstruct text
    output_lines = []
    for sec in new_sections:
        output_lines.extend(sec)
        if output_lines and output_lines[-1] != '':
            output_lines.append('')

    with open(filepath, "w", encoding="utf-8") as f:
        f.write("\n".join(output_lines).rstrip() + "\n")
    print(f"Converted {filepath} successfully.")

if __name__ == "__main__":
    for arg in sys.argv[1:]:
        convert_floor_scene(arg)
