#!/home/pedro/.config/nautilus-custom-scripts/.venv/bin/python
import hashlib
import os
import subprocess
import sys

import pymupdf


class XoppSplitter:
    def __init__(self):
        self.FILE_PATH = os.path.abspath(sys.argv[1])

        if not os.path.exists(self.FILE_PATH):
            self.notify_error("File not found: The specified path does not exist.")
            sys.exit(1)

        if not self.FILE_PATH.lower().endswith(".xopp"):
            self.notify_error("Invalid file format. Please select a .xopp file.")
            sys.exit(1)

        self.FILE_NAME = os.path.basename(self.FILE_PATH)
        self.PAGES: list[int] | None = None
        self.PAGES_STR: str | None = None
        self.SOURCE_PDF_PATH: str | None = None

    def start(self):
        try:
            self.get_pages_from_user()
            self.get_or_create_pdf()
            self.split_pdf()
        except Exception as e:
            self.notify_error(f"An unexpected error occurred: {str(e)}")
            sys.exit(1)

    def create_pages_arr(self, pages_str: str) -> list[int]:
        try:
            pages = []
            for part in pages_str.split(","):
                if "-" in part:
                    start, end = map(int, part.split("-"))
                    if start < 1 or end < 1:
                        raise ValueError("Page numbers must be greater than 1.")
                    pages.extend(range(start - 1, end))
                    continue
                page = int(part)
                if page < 1:
                    raise ValueError("Page numbers must be greater than 1.")
                pages.append(page - 1)
            return pages
        except ValueError as ve:
            raise ValueError("Invalid page range or format.") from ve
        except Exception as e:
            raise Exception("An error occurred while processing pages.") from e

    def get_pages_from_user(self):
        try:
            resultado = subprocess.run(
                [
                    "zenity",
                    "--entry",
                    "--title=XOPP to PDF Splitter",
                    "--text=Pages to extract (Example: '1-3, 5, 7-9'):",
                ],
                capture_output=True,
                text=True,
            )
            if resultado.returncode == 0:
                self.PAGES_STR = resultado.stdout.strip()
                if not self.PAGES_STR:
                    self.notify_error("No input provided. Please enter the pages.")
                    sys.exit(1)

                try:
                    self.PAGES = self.create_pages_arr(self.PAGES_STR)
                except ValueError as ve:
                    self.notify_error(str(ve))
                    sys.exit(1)
            else:
                sys.exit(0)
        except Exception as e:
            self.notify_error(f"An error occurred while getting the pages: {str(e)}")
            sys.exit(1)

    def get_or_create_pdf(self):
        try:
            original_base_name, _ = os.path.splitext(self.FILE_NAME)

            # 1. Tenta achar um PDF exportado manualmente por você na mesma pasta
            local_pdf = os.path.join(
                os.path.dirname(self.FILE_PATH), f"{original_base_name}.pdf"
            )

            # 2. Define o nome do cache no /tmp usando um hash do caminho para evitar colisões
            path_hash = hashlib.md5(self.FILE_PATH.encode()).hexdigest()[:8]
            cache_pdf = f"/tmp/xopp_cache_{original_base_name}_{path_hash}.pdf"

            xopp_mtime = os.path.getmtime(self.FILE_PATH)

            # Checa se o PDF local existe e está atualizado
            if os.path.exists(local_pdf) and os.path.getmtime(local_pdf) >= xopp_mtime:
                self.SOURCE_PDF_PATH = local_pdf
                return

            # Checa se o cache no /tmp existe e está atualizado
            if os.path.exists(cache_pdf) and os.path.getmtime(cache_pdf) >= xopp_mtime:
                self.SOURCE_PDF_PATH = cache_pdf
                return

            # Se não achou nenhum válido, aciona o Xournal++ para gerar um novo cache
            resultado = subprocess.run(
                ["xournalpp", "-p", cache_pdf, self.FILE_PATH],
                capture_output=True,
                text=True,
            )

            if resultado.returncode != 0:
                raise Exception(f"Xournal++ export failed: {resultado.stderr}")

            self.SOURCE_PDF_PATH = cache_pdf

        except Exception as e:
            self.notify_error(f"Error handling PDF conversion: {str(e)}")
            sys.exit(1)

    def notify_error(self, message: str):
        try:
            subprocess.run(
                [
                    "notify-send",
                    "XOPP Splitter - Error",
                    message,
                ]
            )
        except Exception:
            print(f"Notification Error: {message}")

    def split_pdf(self):
        try:
            pdf = pymupdf.open(self.SOURCE_PDF_PATH)
            pdf.select(self.PAGES)

            original_base_name, ext = os.path.splitext(self.FILE_NAME)

            if self.PAGES_STR is None:
                self.notify_error("Pages string is not set.")
                sys.exit(1)

            safe_pages_str = self.PAGES_STR.replace(" ", "")

            new_file_name = f"{original_base_name}-{safe_pages_str}.pdf"
            output_name = os.path.join(os.path.dirname(self.FILE_PATH), new_file_name)

            base_name, file_ext = os.path.splitext(output_name)
            counter = 1

            while os.path.exists(output_name):
                output_name = f"{base_name}({counter}){file_ext}"
                counter += 1

            pdf.save(
                output_name,
                garbage=4,
                clean=True,
                deflate=True,
            )
        except Exception:
            self.notify_error("An error occurred while generating the final PDF")
            sys.exit(1)


if __name__ == "__main__":
    try:
        splitter = XoppSplitter()
        splitter.start()
    except Exception as e:
        subprocess.run(
            [
                "notify-send",
                "XOPP Splitter - Critical Error",
                f"An unrecoverable error occurred: {str(e)}",
            ]
        )
        sys.exit(1)
