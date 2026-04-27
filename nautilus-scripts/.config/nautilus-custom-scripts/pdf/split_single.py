#!/home/pedro/.config/nautilus-custom-scripts/.venv/bin/python
import os
import subprocess
import sys

import pymupdf


class PDFSplitter:
    def __init__(self):
        self.PDF_PATH = sys.argv[1]
        if not os.path.exists(self.PDF_PATH):
            self.notify_error(
                "File not found: The specified path for the PDF does not exist."
            )
            sys.exit(1)
        self.PDF_NAME = os.path.basename(self.PDF_PATH)
        self.PAGES: list[int] | None = None
        self.PAGES_STR: str | None = None

    def start(self):
        try:
            self.get_pages_from_user()
            self.split_pdf()
        except Exception as e:
            self.notify_error(f"An unexpected error occurred: {str(e)}")
            sys.exit(1)
        pass

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
                    "--title=PDF Splitter",
                    "--text=Example: '1-3, 5, 7-9'",
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

    def notify_error(self, message: str):
        try:
            subprocess.run(
                [
                    "notify-send",
                    "PDF Splitter - Error",
                    message,
                ]
            )
        except Exception:
            print(f"Notification Error: {message}")

    def split_pdf(self):
        try:
            pdf = pymupdf.open(self.PDF_PATH)
            pdf.select(self.PAGES)

            output_name = os.path.join(
                os.path.dirname(self.PDF_PATH), f"{self.PDF_NAME}_{self.PAGES_STR}"
            )
            base_name, extension = os.path.splitext(output_name)
            counter = 1

            while os.path.exists(output_name):
                output_name = f"{base_name}({counter}){extension}"
                counter += 1

            pdf.save(output_name)
        except Exception:
            self.notify_error("An error occurred while splitting the PDF")
            sys.exit(1)


if __name__ == "__main__":
    try:
        pdf_splitter = PDFSplitter()
        pdf_splitter.start()
    except Exception as e:
        subprocess.run(
            [
                "notify-send",
                "PDF Splitter - Critical Error",
                f"An unrecoverable error occurred: {str(e)}",
            ]
        )
        sys.exit(1)
    pass
