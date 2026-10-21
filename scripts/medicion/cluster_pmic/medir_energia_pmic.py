#!/usr/bin/env python3
"""
medir_energia_pmic.py
======================
Medidor de consumo energetico para Raspberry Pi 5 mediante hardware PMIC Renesas DA9091.
Captura fisica directa de voltaje y corriente en los 12 rieles del SoC mediante `vcgencmd pmic_read_adc`.
Compatible de forma nativa con Slurm y SSH (sin necesidad de root ni sudo).

USO:
  python3 medir_energia_pmic.py --etiqueta test
  python3 medir_energia_pmic.py -e kraken2_c001 -i 1.0 -o /shared/users/grupo1/lemmi16s/medicion_energia
  python3 medir_energia_pmic.py -e baseline -d 60
  Ctrl+C o SIGTERM para finalizar y generar el reporte.
"""

import argparse
import csv
import os
import signal
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path


def leer_potencia_pmic():
    """
    Ejecuta 'vcgencmd pmic_read_adc' una sola vez y calcula la potencia total en Watts
    sumando el producto de corriente (A) y voltaje (V) de todos los rieles del Renesas DA9091.
    Usa 'vcgencmd' directo o 'sg video' si Slurm no heredo el grupo secundario del nodo.
    No requiere root ni sudo.
    """
    salida = None

    # 1. Intento directo (funciona cuando /dev/vcio es 666 o el grupo ya esta en el shell)
    try:
        out = subprocess.check_output(
            ["vcgencmd", "pmic_read_adc"],
            stderr=subprocess.DEVNULL,
            timeout=3.0
        ).decode("utf-8", errors="replace")
        if "VDD_CORE" in out:
            salida = out
    except Exception:
        pass

    # 2. Si falla en Slurm, invocar via 'sg video' (activa el grupo 'video' que el usuario ya posee en el nodo)
    if salida is None:
        try:
            out = subprocess.check_output(
                ["sg", "video", "-c", "vcgencmd pmic_read_adc"],
                stderr=subprocess.DEVNULL,
                timeout=3.0
            ).decode("utf-8", errors="replace")
            if "VDD_CORE" in out:
                salida = out
        except Exception:
            pass

    if salida is None:
        return None

    corrientes = {}
    voltajes = {}

    for linea in salida.strip().splitlines():
        linea = linea.strip()
        if "=" not in linea:
            continue
        partes = linea.split("=")
        if len(partes) != 2:
            continue

        header = partes[0].split()[0].strip()  # ej: "VDD_CORE_A" o "VDD_CORE_V"
        valor_str = partes[1].strip()          # ej: "0.83942000A" o "0.86791120V"

        if header.endswith("_A") and valor_str.endswith("A"):
            riel = header[:-2]
            try:
                corrientes[riel] = float(valor_str[:-1])
            except ValueError:
                pass
        elif header.endswith("_V") and valor_str.endswith("V"):
            riel = header[:-2]
            try:
                voltajes[riel] = float(valor_str[:-1])
            except ValueError:
                pass

    # Sumar la potencia de cada riel (P = V * I)
    potencia_total = sum(corrientes[r] * voltajes[r] for r in corrientes if r in voltajes)
    canales_validos = sum(1 for r in corrientes if r in voltajes)

    # RPi 5 tiene 12 rieles principales de computo y perifericos
    if canales_validos >= 4 and potencia_total > 0:
        return potencia_total

    return None


def main():
    parser = argparse.ArgumentParser(
        description="Medidor de consumo energetico para Raspberry Pi 5 mediante PMIC Renesas DA9091"
    )
    parser.add_argument("-e", "--etiqueta", default="test", help="Etiqueta del run (sufijo en nombre de archivo CSV)")
    parser.add_argument("-i", "--intervalo", type=float, default=1.0, help="Intervalo de muestreo en segundos (default: 1.0)")
    parser.add_argument("-o", "--outdir", default=".", help="Directorio donde se guardara el CSV (default: actual)")
    parser.add_argument("-d", "--duration", type=float, default=None, help="Duracion fija de la medicion en segundos (opcional)")
    args = parser.parse_args()

    outdir = Path(args.outdir).resolve()
    outdir.mkdir(parents=True, exist_ok=True)
    timestamp_archivo = datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_path = outdir / f"energia_{args.etiqueta}_{timestamp_archivo}.csv"

    # Verificacion previa de acceso al hardware PMIC
    potencia_test = leer_potencia_pmic()
    if potencia_test is None:
        print("[ERROR CRITICO] No se puede leer el chip PMIC via 'vcgencmd pmic_read_adc'.", file=sys.stderr)
        print("Causas posibles:", file=sys.stderr)
        print(" 1. El usuario no pertenece al grupo 'video' en este nodo y /dev/vcio no tiene permisos 666.", file=sys.stderr)
        print(" 2. El comando 'vcgencmd' no esta instalado o no se ejecuta en una Raspberry Pi 5.", file=sys.stderr)
        sys.exit(1)

    print("=" * 65)
    print("=== Medicion de Energia Raspberry Pi 5 (PMIC Hardware) ===")
    print("=" * 65)
    print(f"Etiqueta:          {args.etiqueta}")
    print(f"Intervalo:         {args.intervalo} s")
    print(f"Hardware:          Renesas DA9091 PMIC (12 Canales ADC)")
    print(f"Directorio salida: {outdir}")
    print(f"Archivo de salida: {csv_path.name}")
    if args.duration:
        print(f"Duracion fija:     {args.duration} s")
    print("Presiona Ctrl+C o envia SIGTERM para detener la medicion.\n")

    energia_wh = 0.0
    muestras = 0
    inicio = datetime.now()
    tiempo_prev = time.monotonic()
    inicio_monot = tiempo_prev

    csv_file = open(csv_path, "w", newline="")
    writer = csv.writer(csv_file)
    writer.writerow(["timestamp", "power_w"])

    detener = {"flag": False}

    def manejar_detencion(sig, frame):
        detener["flag"] = True

    signal.signal(signal.SIGINT, manejar_detencion)
    signal.signal(signal.SIGTERM, manejar_detencion)

    try:
        while not detener["flag"]:
            # Dormir en micropasos de 0.1s para reaccionar inmediatamente a Ctrl+C o SIGTERM
            pasos = max(1, int(args.intervalo / 0.1))
            sleep_step = args.intervalo / pasos
            for _ in range(pasos):
                if detener["flag"]:
                    break
                time.sleep(sleep_step)

            if detener["flag"]:
                break

            tiempo_actual = time.monotonic()
            if args.duration and (tiempo_actual - inicio_monot) >= args.duration:
                detener["flag"] = True

            delta_t = tiempo_actual - tiempo_prev
            tiempo_prev = tiempo_actual

            watts = leer_potencia_pmic()
            ahora_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S.%f")[:-3]

            if watts is not None:
                writer.writerow([ahora_str, f"{watts:.3f}"])
                csv_file.flush()
                energia_wh += (watts * delta_t) / 3600.0
                muestras += 1
                print(
                    f"\r[{ahora_str}] [PMIC] Power: {watts:5.2f} W | "
                    f"Energia: {energia_wh:.4f} Wh | Muestras: {muestras}",
                    end="",
                    flush=True
                )
            else:
                print(f"\r[{ahora_str}] [PMIC] Advertencia: Lectura nula del conversor ADC", end="", flush=True)

    finally:
        csv_file.close()
        fin = datetime.now()
        duracion_seg = (fin - inicio).total_seconds()
        potencia_promedio = (energia_wh * 3600.0) / duracion_seg if duracion_seg > 0 else 0.0

        print("\n")
        print(f"=== Resumen de medicion ({args.etiqueta}) ===")
        print(f"Inicio:           {inicio}")
        print(f"Fin:              {fin}")
        print(f"Duracion:         {duracion_seg:.1f} s ({duracion_seg/60:.2f} min)")
        print(f"Muestras tomadas: {muestras}")
        print(f"Energia total:    {energia_wh:.4f} Wh")
        print(f"Potencia promedio: {potencia_promedio:.2f} W")
        print(f"CSV guardado en:  {csv_path.name}")
        print()
        print("Recuerda: resta el consumo baseline (standby) medido por separado")
        print("para obtener la energia neta atribuible al pipeline.")
        print()


if __name__ == "__main__":
    main()
