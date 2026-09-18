# Samos

『임베디드 OS 개발 프로젝트』를 따라 ARM 부팅 코드와 임베디드 OS 개발을 학습하는 저장소입니다.

현재는 `MOV R0, R1` 명령을 포함한 최소 부팅 코드를 빌드하고, QEMU와 GDB로 메모리 적재 상태를 확인하는 단계입니다.

## 파일 구성

- `boot/Entry.S`: ARM 어셈블리 시작 코드
- `samos.ld`: 시작 심벌과 섹션의 메모리 배치를 지정하는 링커 스크립트

## 빌드

WSL의 Ubuntu에서 ARM GNU Binutils가 설치된 상태로 저장소 폴더에서 실행합니다.

```sh
arm-none-eabi-as -mcpu=cortex-a8 -o boot/Entry.o boot/Entry.S
arm-none-eabi-ld -n -T samos.ld -nostdlib -o samos.axf boot/Entry.o
arm-none-eabi-objdump -d samos.axf
```

`vector_start`가 주소 `0x00000000`에 배치되고, `mov r0, r1`의 기계어가 `e1a00001`로 표시되는지 확인합니다.

## QEMU와 GDB로 확인

`qemu-system-arm`과 `gdb-multiarch`가 필요합니다.

첫 번째 WSL 터미널에서:

```sh
qemu-system-arm -M realview-pb-a8 -kernel samos.axf -S -gdb tcp:127.0.0.1:1234
```

두 번째 WSL 터미널에서 같은 저장소 폴더로 이동한 뒤:

```sh
gdb-multiarch samos.axf
```

GDB 프롬프트에서:

```gdb
target remote 127.0.0.1:1234
x/4bx 0x0
x/1wx 0x0
```

바이트 단위로는 `0x01 0x00 0xa0 0xe1`, 32비트 값으로는 `0xe1a00001`이 보이면 코드가 메모리에 적재된 것입니다. `-S` 옵션 때문에 CPU는 아직 실행을 시작하지 않은 상태입니다.
