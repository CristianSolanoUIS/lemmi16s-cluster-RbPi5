#!/usr/bin/env bash
# Solo LEE. Lista todo lo de LotuS3 que hay en el cluster (salidas, energia, tmp, logs, instancias)
# con fecha y tamano, para decidir que se limpia. No toca Kraken2 ni QIIME2.
B=/shared/users/grupo1/lemmi16s
L=/shared/users/grupo1/logs_slurm

seccion() { echo; echo "######## $1"; }

seccion "Disco"
df -h /shared | tail -1

seccion "analysis_outputs/lotus3*"
for d in $B/benchmark/analysis_outputs/lotus3*; do
    [ -e "$d" ] || continue
    echo "== $d ($(du -sh "$d" | cut -f1))"
    find "$d" -maxdepth 2 -printf '%TY-%Tm-%Td %TH:%TM  %8s  %P\n' | sort
done

seccion "medicion_energia (solo lotus3)"
find $B/medicion_energia -ipath '*lotus*' -printf '%TY-%Tm-%Td %TH:%TM  %8s  %P\n' | sort
find $B/medicion_energia -maxdepth 1 -iname '*lotus*' -printf '%P\n'

seccion "benchmark/tmp (solo lotus)"
find $B/benchmark/tmp -maxdepth 1 -iname '*lotus*' -printf '%TY-%Tm-%Td %TH:%TM  %P\n' | sort
for d in $B/benchmark/tmp/*lotus*; do [ -e "$d" ] && echo "   $(du -sh "$d")"; done

seccion "instances (HM_Contaminated_Soil*)"
for d in $B/benchmark/instances/HM_Contaminated_Soil*; do [ -e "$d" ] && echo "$(du -sh "$d")"; done

seccion "logs_slurm (solo lotus)"
find $L -maxdepth 1 -iname '*lotus*' -printf '%TY-%Tm-%Td %TH:%TM  %8s  %P\n' | sort

seccion "scripts sbatch de lotus en el repo"
find $B/scripts $B/workflow/scripts -iname '*lotus*' 2>/dev/null -printf '%TY-%Tm-%Td %TH:%TM  %P\n' | sort

seccion "Otros archivos lotus sueltos en el home de grupo1 (nivel 2)"
find /shared/users/grupo1 -maxdepth 2 -iname '*lotus*' -printf '%TY-%Tm-%Td %TH:%TM  %P\n' | sort

seccion "Entornos"
ls -d /shared/users/grupo1/*env* /shared/users/grupo1/*_arm64 2>/dev/null

seccion "Slurm"
sinfo -N -p partition1 2>/dev/null | head -15
squeue -u grupo1 2>/dev/null
