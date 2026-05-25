#!/home/pedro/.config/nautilus-custom-scripts/.venv/bin/python
import os
import subprocess
import sys


class XoppToPdfBatchConverter:
    def __init__(self):
        # sys.argv[1:] contém a lista de todos os caminhos de arquivos passados pelo Nautilus
        self.files = sys.argv[1:]

        if not self.files:
            self.notify("Erro", "Nenhum arquivo fornecido ao script.")
            sys.exit(1)

    def start(self):
        sucessos = 0
        falhas = 0
        erros_detalhes = []

        # Processa cada arquivo da lista
        for file_path in self.files:
            file_path = os.path.abspath(file_path)
            file_name = os.path.basename(file_path)

            if not os.path.exists(file_path):
                falhas += 1
                erros_detalhes.append(f"{file_name} (Não encontrado)")
                continue

            if not file_path.lower().endswith(".xopp"):
                falhas += 1
                erros_detalhes.append(f"{file_name} (Não é .xopp)")
                continue

            # Tenta converter
            try:
                self.convert_to_pdf(file_path)
                sucessos += 1
            except Exception as e:
                falhas += 1
                erros_detalhes.append(f"{file_name} (Erro na conversão)")

        # Envia o resumo final das operações
        self.send_summary(sucessos, falhas, erros_detalhes)

    def convert_to_pdf(self, file_path: str):
        # Define o caminho de saída (mesma pasta, troca .xopp por .pdf)
        base_name = os.path.splitext(file_path)[0]
        output_pdf = f"{base_name}.pdf"

        # Executa o Xournal++ em background
        resultado = subprocess.run(
            ["xournalpp", "-p", output_pdf, file_path],
            capture_output=True,
            text=True,
        )

        if resultado.returncode != 0:
            raise Exception(f"Falha na exportação: {resultado.stderr}")

    def send_summary(self, sucessos: int, falhas: int, erros: list):
        title = "Resumo da Conversão"

        if falhas == 0:
            message = f"Todos os {sucessos} arquivos foram convertidos com sucesso!"
        else:
            message = f"{sucessos} arquivos convertidos.\n{falhas} falharam."
            if erros:
                # Mostra até 3 erros no popup para não ficar gigante
                message += f"\nProblemas em: {', '.join(erros[:3])}"
                if len(erros) > 3:
                    message += "..."

        self.notify(title, message)

    def notify(self, title: str, message: str):
        try:
            subprocess.run(
                [
                    "notify-send",
                    f"XOPP to PDF - {title}",
                    message,
                ]
            )
        except Exception:
            print(f"Notification Error: {message}")


if __name__ == "__main__":
    try:
        converter = XoppToPdfBatchConverter()
        converter.start()
    except Exception as e:
        subprocess.run(
            [
                "notify-send",
                "XOPP to PDF - Erro Crítico",
                f"Ocorreu um erro irrecuperável: {str(e)}",
            ]
        )
        sys.exit(1)
