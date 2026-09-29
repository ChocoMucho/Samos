# Samos

『임베디드 OS 개발 프로젝트』를 따라 ARM 부팅 코드와 임베디드 OS 개발을 학습하는 저장소입니다.

현재는 익셉션 벡터 테이블의 기본 구조를 작성하고, QEMU와 GDB로 메모리 적재 상태와 명령어 실행 흐름을 살펴보는 단계입니다.

## 개발 환경

- WSL의 Ubuntu
- ARMv7-A / Cortex-A8, ARM 32비트 명령어 모드
- QEMU 가상 보드: `realview-pb-a8`

빌드에는 `make`와 ARM GNU Binutils의 `arm-none-eabi-as`, `arm-none-eabi-ld`, `arm-none-eabi-objcopy`가 필요합니다. 디스어셈블에는 `arm-none-eabi-objdump`, 실행과 디버깅에는 `qemu-system-arm`, `gdb-multiarch`를 사용합니다.

## 파일 구성

| 파일 | 역할 |
| --- | --- |
| `boot/Entry.S` | 익셉션 벡터 테이블, 핸들러 주소, 초기 핸들러 코드 |
| `samos.ld` | 시작 심벌과 섹션의 메모리 배치를 지정하는 링커 스크립트 |
| `Makefile` | 어셈블·링크·바이너리 변환과 QEMU/GDB 실행 명령 |
| `.gitignore` | 빌드 결과물과 편집기 임시 파일 제외 규칙 |

## 현재 코드의 동작

`vector_start`는 주소 `0x00000000`에 배치됩니다. 벡터 테이블의 각 슬롯에는 4바이트 ARM 명령어 하나가 들어갑니다.

- 리셋 벡터의 `LDR PC, reset_handler_addr`는 해당 라벨에 저장된 주소를 읽어 `reset_handler`로 이동합니다.
- `.word reset_handler`는 핸들러 주소를 4바이트 데이터로 배치합니다.
- `reset_handler`는 `R0`에 `0x10000000`을 넣고, 그 주소에서 읽은 32비트 값을 `R1`에 저장합니다.
- 이후 바로 뒤의 `dummy_handler`로 실행이 이어져 `B .`에서 반복합니다.
- 나머지 익셉션 벡터는 `dummy_handler`로 연결되어 있고, 예약된 벡터 슬롯은 `B .`로 반복합니다.

아직 익셉션별 실제 처리나 레지스터 저장·복귀는 구현하지 않았습니다. 화면에 문자를 출력하는 코드도 없으므로 GDB로 실행 상태를 확인합니다.

## 빌드와 실행

저장소 폴더에서 실행합니다.

```sh
make all
```

빌드 과정에서 다음 파일이 생성됩니다.

- `build/Entry.o`: 어셈블리 소스를 변환한 목적 파일
- `build/samos.axf`: 링커 스크립트에 따라 배치한 ELF 실행 파일
- `build/samos.bin`: 실행 파일을 변환한 바이너리 이미지

명령어 배치는 다음과 같이 확인할 수 있습니다.

```sh
arm-none-eabi-objdump -d build/samos.axf
```

| 명령 | 동작 |
| --- | --- |
| `make all` | 빌드 결과물 생성 |
| `make run` | QEMU에서 실행 |
| `make debug` | QEMU를 시작하고 CPU를 정지한 채 GDB 연결 대기 |
| `make gdb` | `gdb-multiarch` 실행 |
| `make clean` | `build/` 디렉터리 삭제 |

## QEMU와 GDB로 확인

첫 번째 WSL 터미널에서 저장소 폴더로 이동한 뒤 실행합니다.

```sh
make debug
```

QEMU는 `-S` 옵션으로 CPU 실행을 멈춘 상태에서 TCP 1234번 포트로 GDB 연결을 기다립니다.

두 번째 WSL 터미널에서도 같은 저장소 폴더로 이동한 뒤 실행합니다.

```sh
make gdb
```

`make gdb`는 디버거만 시작합니다. GDB 프롬프트에서 실행 파일의 심벌 정보를 읽고 QEMU에 연결합니다.

```gdb
file build/samos.axf
target remote 127.0.0.1:1234
x/8i 0x0
x/i $pc
stepi
x/i $pc
```

- `file`: 실행 파일의 심벌 정보를 GDB에 읽어들입니다. QEMU의 메모리에 코드를 적재하는 작업은 `make debug`의 `-kernel` 옵션이 담당합니다.
- `target remote`: 실행 중인 QEMU의 디버깅 포트에 연결합니다.
- `x/8i 0x0`: 주소 0부터 벡터 테이블의 명령어 8개를 확인합니다.
- `x/i $pc`: 현재 PC가 가리키는 명령어를 확인합니다.
- `stepi`: 명령어 하나를 실행합니다. 리셋 벡터의 명령어를 실행하면 PC가 `reset_handler`로 이동합니다.

`stepi`로 리셋 핸들러의 두 명령어까지 실행한 뒤 다음 명령으로 레지스터 값을 확인할 수 있습니다.

```gdb
info registers r0 r1 pc
```

## Git에 저장하는 파일

소스 코드, 링커 스크립트, Makefile과 문서를 관리합니다. `.gitignore`에 등록된 `*.o`, `*.bin`, `*.axf`, `*.elf`, `*.map` 등의 빌드 결과물은 커밋에서 제외합니다.
