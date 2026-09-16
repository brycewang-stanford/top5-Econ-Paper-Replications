#!/bin/bash
# Parallel ranged download of the Harvard Dataverse package doi:10.7910/DVN/TJCTC7 (per-file API, S3 redirect).
# Usage: bash download.sh   (resumable; verifies size + md5)
cd "$(dirname "$0")"
NP=6
getpart() { # id name start end idx
  local id=$1 name=$2 start=$3 end=$4 i=$5 f="$2.part$5" need=$(( $4 - $3 + 1 ))
  for try in $(seq 1 40); do
    local have=$(stat -f %z "$f" 2>/dev/null || echo 0)
    [ "$have" -ge "$need" ] && return 0
    local url=$(curl -s -o /dev/null -w '%{redirect_url}' "https://dataverse.harvard.edu/api/access/datafile/$id")
    curl -s -r $(( start + have ))-$end "$url" >> "$f"
    sleep 2
  done
}
dl() { # id name size md5
  local id=$1 name=$2 size=$3 md5=$4
  if [ -f "$name" ] && [ "$(stat -f %z "$name")" = "$size" ]; then echo "$name already complete"; else
    local chunk=$(( (size + NP - 1) / NP ))
    for i in $(seq 0 $((NP-1))); do
      s=$(( i*chunk )); e=$(( s+chunk-1 )); [ $e -ge $size ] && e=$((size-1))
      getpart $id $name $s $e $i &
    done; wait
    cat $(for i in $(seq 0 $((NP-1))); do echo "$name.part$i"; done) > "$name"
  fi
  local m=$(md5 -q "$name"); echo "$name size=$(stat -f %z "$name") md5ok=$([ "$m" = "$md5" ] && echo yes || echo NO)"
  [ "$m" = "$md5" ] && rm -f "$name".part*
}
dl 3588726 Readme.txt 3390 69170738d3ca457d81d7c321f14ea28a
dl 3588722 zipfordataverse.sh 853 c450ee9699cadee53f5b535a670edc32
dl 3588739 dofiles.zip 276272 b3a55d08bc05c1bb2fafea9169237790
dl 3588740 estimates.zip 1141159 2143a62e154d0947f6b7da8cbc211c71
dl 3588725 figures.zip 383722 a5ce5accc9ea0111dff551aa1f2fd066
dl 3588727 tables.zip 9736 c74646b65fc5a09eafeb133dd8817395
dl 3588738 data3.zip 1452920351 a3aff23b9fdd19d6620590316df0cffc &
dl 3588720 data1.zip 2034430385 1394ae60b51570f21ffe0fc47ff9a75b &
dl 3588721 data2.zip 2055295418 12f800df4eab71e5888fce05bbe07511 &
wait
echo ALLDONE
