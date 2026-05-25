import os
import subprocess
from gi.repository import Nautilus, GObject

SCRIPTS_BASE_DIR = os.path.expanduser("~/.config/nautilus-custom-scripts")


class DynamicScriptMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()

    def get_file_items(self, files):
        if not files:
            return None

        num_files = len(files)
        extensions = set()

        for f in files:
            if f.is_directory():
                return None

            ext = os.path.splitext(f.get_name())[1].lower().strip(".")
            if ext:
                extensions.add(ext)

        if len(extensions) != 1:
            return None

        target_extension = extensions.pop()
        ext_dir = os.path.join(SCRIPTS_BASE_DIR, target_extension)

        if not os.path.isdir(ext_dir):
            return None

        available_scripts = []
        try:
            for entry in os.scandir(ext_dir):
                if entry.is_file() and os.access(entry.path, os.X_OK):
                    original_name = os.path.splitext(entry.name)[0]

                    is_single = original_name.endswith("_single")

                    if is_single and num_files > 1:
                        continue

                    clean_name = (
                        original_name.replace("_single", "")
                        if is_single
                        else original_name
                    )

                    display_name = clean_name.replace("_", " ").title()

                    available_scripts.append({"name": display_name, "path": entry.path})

        except PermissionError:
            return None

        if not available_scripts:
            return None

        available_scripts.sort(key=lambda x: x["name"])

        top_menuitem = Nautilus.MenuItem(
            name="DynamicScriptsProvider::MenuPrincipal",
            label="Scripts",
            tip="Executar scripts personalizados",
        )

        submenu = Nautilus.Menu()
        top_menuitem.set_submenu(submenu)

        for i, script in enumerate(available_scripts):
            item = Nautilus.MenuItem(
                name=f"DynamicScriptsProvider::Script_{i}",
                label=script["name"],
                tip=f"Executar: {script['name']}",
            )
            item.connect("activate", self.execute_script, script["path"], files)
            submenu.append_item(item)

        return [top_menuitem]

    def execute_script(self, menu, script_path, files):
        paths = [
            f.get_location().get_path() for f in files if f.get_location().get_path()
        ]

        if paths:
            subprocess.Popen([script_path] + paths)
