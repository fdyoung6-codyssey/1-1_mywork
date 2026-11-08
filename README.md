# 내 컴퓨터에 개발자용 '작업실' 꾸미기

터미널, Docker, Git/GitHub를 직접 세팅하고, 실행 결과(로그·접속·데이터 유지)로 동작을 검증한 개발 워크스테이션 구축 기록입니다.

---

## 1. 프로젝트 개요

| 목표 | 수행 내용 |
|---|---|
| 터미널 기본기 | 작업 디렉토리 구성, 파일 생성·복사·이동·삭제, 권한(chmod) 변경 |
| Docker 설치·운영 | Docker 설치 점검, 이미지·컨테이너 실행/중지/로그/리소스 확인 |
| 커스텀 이미지 | `nginx:alpine` 기반 Dockerfile 작성 → 내 웹 페이지를 담은 이미지 빌드 |
| 네트워크·스토리지 | 포트 매핑 접속, 바인드 마운트 변경 반영, 볼륨 데이터 영속성 검증 |
| 버전 관리·협업 | Git 설정, GitHub 저장소 연결, VSCode GitHub 로그인 및 push |

---

## 2. 실행 환경

| 항목 | 내용 |
|---|---|
| 호스트 OS | Windows + WSL2 |
| Linux 배포판 | Ubuntu 26.04.1 LTS (WSL2) |
| 커널 | 6.18.54.1-microsoft-standard-WSL2 |
| Shell | bash (`/bin/bash`) |
| 터미널 | VSCode 통합 터미널 (WSL: Ubuntu) |
| Docker | Docker version 29.9.2 (Docker Desktop 4.97.0, WSL2 백엔드) |
| Git | git version 2.53.0 |
| 에디터 | Visual Studio Code + WSL 확장 |

### 재현 시 주의사항

- 이 기록은 **Windows + WSL2(Ubuntu)** 환경 기준입니다. Windows에서는 PowerShell이 아니라 **WSL Ubuntu 터미널**에서 명령을 실행해야 합니다.
- Docker는 **Docker Desktop**을 설치한 뒤 `Settings → Resources → WSL integration`에서 Ubuntu 연동을 켜야 Ubuntu 터미널에서 `docker` 명령을 쓸 수 있습니다.
- macOS(서울캠퍼스 등 sudo 제한 환경)에서는 Docker Desktop 대신 **OrbStack**을 실행하면 같은 `docker` 명령으로 진행할 수 있습니다.
- 경로 `/home/fdyoung68559/...`는 개인 환경 경로입니다. 다른 환경에서는 `~`(홈 폴더) 기준으로 바꿔 사용하면 됩니다.

---

## 3. 수행 항목 체크리스트

- [x] 터미널 기본 조작 및 작업 폴더 구성
- [x] 권한 변경 실습 (파일 1개, 디렉토리 1개)
- [x] Docker 설치 및 점검 (`docker --version`, `docker info`)
- [x] Docker 기본 운영 명령 (`images`, `ps`, `logs`, `stats`, `stop`)
- [x] hello-world 실행
- [x] ubuntu 컨테이너 진입 및 attach/exec 차이 관찰
- [x] Dockerfile 기반 커스텀 이미지 빌드/실행
- [x] 포트 매핑 접속 (8080, 8081 두 개)
- [x] 바인드 마운트 변경 반영
- [x] Docker 볼륨 영속성
- [x] Git 설정 (사용자 정보, 기본 브랜치)
- [x] VSCode GitHub 로그인 + 저장소 연동 + push

---

## 4. 저장소 구조

```text
.
├── README.md            # 기술 문서 (이 파일)
├── Dockerfile           # nginx:alpine 기반 커스텀 이미지
├── site/
│   └── index.html       # 커스텀 이미지에 COPY되는 웹 페이지
├── bind-site/
│   └── index.html       # 바인드 마운트 실습용 웹 페이지
├── hello.txt            # 터미널·권한 실습 파일
├── backup/
│   └── hello_backup.txt # 복사·이동·이름변경 실습 결과
├── docs/images/         # 수행 증거 스크린샷
└── .gitignore
```

---

## 5. 수행 로그

### 5-1. 터미널 기본 조작

현재 위치 확인, 숨김 파일 포함 목록 확인, 폴더 생성·이동

```bash
$ cd ~
$ pwd
/home/fdyoung68559
$ ls -la
total 28
drwxr-x--- 4 fdyoung68559 fdyoung68559 4096 Nov  3 13:51 .
drwxr-xr-x 3 root         root         4096 Nov  3 13:49 ..
-rw-r--r-- 1 fdyoung68559 fdyoung68559  220 Nov  3 13:49 .bash_logout
-rw-r--r-- 1 fdyoung68559 fdyoung68559 3771 Nov  3 13:49 .bashrc
drwxr-x--- 4 fdyoung68559 fdyoung68559 4096 Nov  3 13:51 .cache
drwxr-x--- 3 fdyoung68559 fdyoung68559 4096 Nov  3 13:51 .config
-rw-rw-r-- 1 fdyoung68559 fdyoung68559    0 Nov  3 13:51 .motd_shown
-rw-r--r-- 1 fdyoung68559 fdyoung68559  807 Nov  3 13:49 .profile
$ mkdir -p codyssey/workstation
$ cd codyssey/workstation
$ pwd
/home/fdyoung68559/codyssey/workstation
```

![터미널 기본 조작](docs/images/01-terminal-basic.png)

빈 파일 생성, 파일 내용 확인, 복사, 이동, 이름 변경, 삭제

```bash
$ touch empty.txt                                   # 빈 파일 생성
$ echo "Hello Codyssey" > hello.txt                 # 내용이 있는 파일 생성
$ cat hello.txt                                     # 파일 내용 확인
Hello Codyssey
$ cp hello.txt hello_copy.txt                       # 복사
$ mkdir backup
$ mv hello_copy.txt backup/                         # 이동
$ mv backup/hello_copy.txt backup/hello_backup.txt  # 이름 변경
$ rm empty.txt                                      # 삭제
$ ls -la
drwxr-xr-x 2 fdyoung68559 fdyoung68559 4096 Nov  3 13:58 backup
-rw-r--r-- 1 fdyoung68559 fdyoung68559   15 Nov  3 13:58 hello.txt
$ ls -la backup
-rw-r--r-- 1 fdyoung68559 fdyoung68559   15 Nov  3 13:58 hello_backup.txt
```

![파일 조작](docs/images/02-file-ops.png)

### 5-2. 권한 실습

`stat -c '%a %A %n'`으로 숫자 표기와 기호 표기를 함께 확인했습니다.

```bash
# 파일: 644 → 600
$ stat -c '%a %A %n' hello.txt
644 -rw-r--r-- hello.txt
$ chmod 600 hello.txt
$ stat -c '%a %A %n' hello.txt
600 -rw------- hello.txt

# 디렉토리: 755 → 700
$ stat -c '%a %A %n' backup
755 drwxr-xr-x backup
$ chmod 700 backup
$ stat -c '%a %A %n' backup
700 drwx------ backup
```

| 대상 | 변경 전 | 변경 후 | 의미 |
|---|---|---|---|
| `hello.txt` | 644 (`rw-r--r--`) | 600 (`rw-------`) | 소유자만 읽기·쓰기 가능, 그룹·기타는 접근 불가 |
| `backup/` | 755 (`rwxr-xr-x`) | 700 (`rwx------`) | 소유자만 목록 보기·생성·진입 가능 |

![권한 변경](docs/images/03-permission.png)

### 5-3. Docker 설치 및 점검

Docker Desktop 실행 후 `Engine running` 확인

![Docker Desktop](docs/images/04-docker-desktop.png)

```bash
$ docker --version
Docker version 29.9.2, build a82e528

$ docker info
Client:
 Version:    29.9.2
 Context:    default
 ...
Server:
 Containers: 0
  Running: 0
  Paused: 0
  Stopped: 0
 Images: 0
 Server Version: 29.9.2
 Storage Driver: overlayfs
 ...
 Kernel Version: 6.18.54.1-microsoft-standard-WSL2
 Operating System: Docker Desktop
 OSType: linux
 Architecture: x86_64
 CPUs: 24
 Total Memory: 15.25GiB
```

`Server:` 영역이 오류 없이 출력되어 Docker 데몬이 정상 동작 중임을 확인했습니다.

![docker version](docs/images/05-docker-version.png)
![docker info server](docs/images/06-docker-info-server.png)

### 5-4. 컨테이너 실행 실습

**hello-world**

```bash
$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
...
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
...

$ docker images
IMAGE                ID             DISK USAGE   CONTENT SIZE
hello-world:latest   c567b231f656   25.9kB       9.49kB

$ docker ps -a
CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS                      NAMES
0be6de0f97aa   hello-world   "/hello"   11 seconds ago   Exited (0) 11 seconds ago   inspiring_napier
```

![hello-world](docs/images/07-hello-world.png)

**ubuntu 컨테이너 진입**

```bash
$ docker run -it --name my-ubuntu ubuntu bash
root@5fa7fdb5d2a3:/# pwd
/
root@5fa7fdb5d2a3:/# ls
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
root@5fa7fdb5d2a3:/# echo "Hello from container"
Hello from container
root@5fa7fdb5d2a3:/# cat /etc/os-release
PRETTY_NAME="Ubuntu 26.04.1 LTS"
...
root@5fa7fdb5d2a3:/# exit

$ docker ps -a
CONTAINER ID   IMAGE    COMMAND   ...   STATUS                     NAMES
5fa7fdb5d2a3   ubuntu   "bash"    ...   Exited (0) 5 seconds ago   my-ubuntu
```

![ubuntu 컨테이너](docs/images/08-ubuntu-container.png)

**attach와 exec 차이 관찰**

```bash
$ docker start my-ubuntu
$ docker ps
... my-ubuntu   Up 5 seconds

$ docker exec -it my-ubuntu bash
root@5fa7fdb5d2a3:/# echo "entered with exec"
entered with exec
root@5fa7fdb5d2a3:/# exit
$ docker ps
... my-ubuntu   Up 24 seconds            # exec 후 exit → 컨테이너 유지

$ docker attach my-ubuntu
root@5fa7fdb5d2a3:/# echo "entered with attach"
entered with attach
root@5fa7fdb5d2a3:/# exit
$ docker ps -a
... my-ubuntu   Exited (0) 5 seconds ago # attach 후 exit → 컨테이너 종료
```

| 명령 | 동작 | exit 후 컨테이너 |
|---|---|---|
| `docker exec` | 컨테이너 안에 **새 bash 프로세스**를 추가로 실행 | 메인 프로세스가 살아 있어 **유지(Up)** |
| `docker attach` | 이미 실행 중인 **메인 bash 프로세스**에 연결 | 메인 프로세스가 끝나 **종료(Exited)** |

![attach exec](docs/images/09-attach-exec.png)

### 5-5. Docker 기본 운영 명령

```bash
$ docker run -d --name log-test ubuntu bash -c 'while true; do echo "tick $(date +%T)"; sleep 2; done'
$ docker ps
... ubuntu   "bash -c 'while true…"   Up 6 seconds   log-test

$ docker logs log-test
tick 05:19:50
tick 05:19:52
tick 05:19:54
tick 05:19:56
tick 05:19:58
tick 05:20:00

$ docker logs --tail 3 log-test
tick 05:20:02
tick 05:20:04
tick 05:20:06

$ docker stats --no-stream
CONTAINER ID   NAME       CPU %   MEM USAGE / LIMIT     MEM %   NET I/O          BLOCK I/O   PIDS
4031b4d9d718   log-test   0.62%   3.207MiB / 15.25GiB   0.02%   1.17kB / 126B    0B / 0B     2

$ docker stop log-test
$ docker ps -a
... log-test   Exited (137) 3 seconds ago
```

`Exited (137)`은 `docker stop`으로 강제 종료(SIGKILL)되었다는 의미입니다.

![logs stats](docs/images/10-logs-stats.png)

### 5-6. 기존 Dockerfile 기반 커스텀 이미지 제작

**선택한 방식: (A) 웹 서버 베이스 이미지 활용** — `nginx:alpine` 공식 이미지를 베이스로, 정적 콘텐츠만 교체했습니다.

```dockerfile
# 기존 nginx 웹 서버 이미지(가벼운 alpine 버전)를 바탕으로 시작
FROM nginx:alpine

# 이미지에 이름표(메타데이터) 붙이기
LABEL org.opencontainers.image.title="codyssey-web"

# 환경변수 설정 (실행 환경 표시용)
ENV APP_ENV=dev

# 내가 만든 웹 페이지를 nginx 기본 페이지 위치에 복사
COPY site/ /usr/share/nginx/html/

# 이 컨테이너는 80번 포트를 사용한다고 표시
EXPOSE 80
```

| 커스텀 포인트 | 목적 |
|---|---|
| `FROM nginx:alpine` | 검증된 공식 웹 서버 이미지를 재사용하고, alpine으로 용량을 줄임 |
| `LABEL` | 이미지에 제목 메타데이터를 붙여 식별하기 쉽게 함 |
| `ENV APP_ENV=dev` | 실행 환경(개발용)을 환경변수로 표시 |
| `COPY site/ ...` | nginx 기본 페이지를 내가 만든 `index.html`로 교체 |
| `EXPOSE 80` | 컨테이너가 사용하는 포트를 문서화 |

```bash
$ docker build -t my-web:1.0 .
[+] Building 4.9s (7/7) FINISHED
 => [internal] load build definition from Dockerfile
 => [internal] load metadata for docker.io/library/nginx:alpine
 => [1/2] FROM docker.io/library/nginx:alpine@sha256:785835ea...
 => [2/2] COPY site/ /usr/share/nginx/html/
 => exporting to image
 => => naming to docker.io/library/my-web:1.0

$ docker images
IMAGE                ID             DISK USAGE   CONTENT SIZE
hello-world:latest   c567b231f656   25.9kB       9.49kB
my-web:1.0           acd065ee5f41   93.6MB       26.3MB
ubuntu:latest        6a06111c3b0a   163MB        45.9MB
```

![docker build](docs/images/11-docker-build.png)

### 5-7. 포트 매핑 및 접속

같은 이미지로 컨테이너 2개를 실행하고, 호스트 포트만 다르게 연결했습니다.

```bash
$ docker run -d -p 8080:80 --name my-web-8080 my-web:1.0
$ docker run -d -p 8081:80 --name my-web-8081 my-web:1.0

$ docker ps
IMAGE        ...   STATUS          PORTS                                     NAMES
my-web:1.0   ...   Up 5 seconds    0.0.0.0:8081->80/tcp, [::]:8081->80/tcp   my-web-8081
my-web:1.0   ...   Up 18 seconds   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   my-web-8080

$ curl http://localhost:8080
...
  <h1>Hello Codyssey!</h1>
  <p>나만의 커스텀 nginx 웹 서버입니다.</p>
...

$ curl http://localhost:8081
...
  <h1>Hello Codyssey!</h1>
...
```

![포트 curl](docs/images/12-port-curl.png)

브라우저 접속 (주소창 포트 포함)

![브라우저 8080](docs/images/13-browser-8080.png)
![브라우저 8081](docs/images/14-browser-8081.png)

### 5-8. 바인드 마운트 반영

원본 `site`는 유지하기 위해 `bind-site`로 복사한 뒤, 호스트 폴더를 컨테이너의 nginx 웹 루트에 연결했습니다.

```bash
$ cp -r site bind-site
$ docker run -d -p 8082:80 --name my-web-bind \
    -v $(pwd)/bind-site:/usr/share/nginx/html nginx:alpine

# 변경 전
$ curl http://localhost:8082
  <h1>Hello Codyssey!</h1>

# 호스트에서 파일만 수정 (컨테이너 재시작·재빌드 없음)
$ sed -i 's/Hello Codyssey!/Hello Bind Mount! (수정됨)/' bind-site/index.html

# 변경 후
$ curl http://localhost:8082
  <h1>Hello Bind Mount! (수정됨)</h1>
```

| | 변경 전 | 변경 후 |
|---|---|---|
| 터미널 | ![](docs/images/15-bind-before-terminal.png) | ![](docs/images/17-bind-after-terminal.png) |
| 브라우저 | ![](docs/images/16-bind-before-browser.png) | ![](docs/images/18-bind-after-browser.png) |

### 5-9. Docker 볼륨 영속성

```bash
$ docker volume create mydata
mydata
$ docker volume ls
DRIVER    VOLUME NAME
local     mydata

$ docker run -d --name vol-test1 -v mydata:/data ubuntu sleep infinity
$ docker exec vol-test1 sh -c "echo 'persistent data test' > /data/hello.txt"
$ docker exec vol-test1 cat /data/hello.txt
persistent data test

# 컨테이너 삭제
$ docker rm -f vol-test1
vol-test1
$ docker ps -a                     # vol-test1 없음

# 같은 볼륨으로 새 컨테이너 실행
$ docker run -d --name vol-test2 -v mydata:/data ubuntu sleep infinity
$ docker exec vol-test2 cat /data/hello.txt
persistent data test               # 컨테이너를 삭제해도 데이터 유지
```

![볼륨](docs/images/19-volume.png)

### 5-10. Git 설정 및 GitHub 연동

**Git 설정** (이메일은 개인정보 보호를 위해 마스킹)

```bash
$ git --version
git version 2.53.0
$ git config --global user.name "fdyoung9-a11y"
$ git config --global user.email "(마스킹)"
$ git config --global init.defaultBranch main
$ git config --list
user.name=fdyoung9-a11y
user.email=(마스킹)
init.defaultbranch=main
```

![git config](docs/images/20-git-config.png)

**GitHub 저장소 생성 → 로컬 저장소 연결 → 첫 커밋**

![GitHub 저장소 생성](docs/images/21-github-repo-created.png)

```bash
$ git init
Initialized empty Git repository in /home/fdyoung68559/codyssey/workstation/.git/
$ git add .
$ git commit -m "feat: 터미널 실습 파일과 Dockerfile 기반 커스텀 웹 서버 추가"
[main (root-commit) 3ff5b07] feat: 터미널 실습 파일과 Dockerfile 기반 커스텀 웹 서버 추가
 6 files changed, 47 insertions(+)
$ git remote add origin https://github.com/fdyoung9-a11y/1-1_mywork.git
$ git remote -v
origin  https://github.com/fdyoung9-a11y/1-1_mywork.git (fetch)
origin  https://github.com/fdyoung9-a11y/1-1_mywork.git (push)
```

![git init commit](docs/images/22-git-init-commit.png)

**VSCode WSL 모드로 저장소 열기 + GitHub 로그인**

![VSCode WSL](docs/images/23-vscode-wsl-workstation.png)
![VSCode GitHub 로그인](docs/images/25-vscode-github-login.png)

**push**

```bash
$ git push -u origin main
...
To https://github.com/fdyoung9-a11y/1-1_mywork.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
$ git log --oneline
3ff5b07 (HEAD -> main, origin/main) feat: 터미널 실습 파일과 Dockerfile 기반 커스텀 웹 서버 추가
```

![git push](docs/images/24-git-push.png)


---

## 6. 검증 방법 요약

| 항목 | 사용한 명령 | 확인한 내용 | 증거 |
|---|---|---|---|
| 터미널 조작 | `pwd`, `ls -la`, `cp`, `mv`, `rm` | 위치·목록·파일 변화 | [5-1](#5-1-터미널-기본-조작) |
| 권한 | `stat -c '%a %A %n'`, `chmod` | 644→600, 755→700 | [5-2](#5-2-권한-실습) |
| Docker 동작 | `docker --version`, `docker info` | 버전 29.9.2, Server 정상 응답 | [5-3](#5-3-docker-설치-및-점검) |
| 컨테이너 실행 | `docker run hello-world`, `docker ps -a` | `Hello from Docker!`, `Exited (0)` | [5-4](#5-4-컨테이너-실행-실습) |
| attach/exec | `docker exec`, `docker attach`, `docker ps` | exec 후 Up, attach 후 Exited | [5-4](#5-4-컨테이너-실행-실습) |
| 운영 명령 | `docker logs`, `docker stats`, `docker stop` | 로그 출력, CPU·메모리 사용량 | [5-5](#5-5-docker-기본-운영-명령) |
| 커스텀 이미지 | `docker build`, `docker images` | `FINISHED`, `my-web:1.0` 생성 | [5-6](#5-6-기존-dockerfile-기반-커스텀-이미지-제작) |
| 포트 매핑 | `docker ps`, `curl`, 브라우저 | 8080·8081 모두 응답 | [5-7](#5-7-포트-매핑-및-접속) |
| 바인드 마운트 | `sed`, `curl`, 브라우저 | 재시작 없이 내용 변경 반영 | [5-8](#5-8-바인드-마운트-반영) |
| 볼륨 | `docker rm -f`, `docker exec ... cat` | 컨테이너 삭제 후에도 데이터 유지 | [5-9](#5-9-docker-볼륨-영속성) |
| Git/GitHub | `git config --list`, `git push`, `git log` | 설정 3줄, `origin/main` 동기화 | [5-10](#5-10-git-설정-및-github-연동) |

---

## 7. 트러블슈팅

### 7-1. PowerShell에서 리눅스 명령이 동작하지 않음

- **문제**: VSCode 기본 터미널(PowerShell)에서 `ls -la` 실행 시 `매개 변수 이름 'la'과(와) 일치하는 매개 변수를 찾을 수 없습니다` 오류
- **원인 가설**: PowerShell의 `ls`는 리눅스 `ls`가 아니라 `Get-ChildItem`의 별칭이라 `-la` 옵션을 모를 것
- **확인**: 터미널이 `PS C:\...>` 형태의 PowerShell임을 확인, `wsl -l -v` 실행 시 WSL 미설치 안내 출력
- **해결**: 관리자 PowerShell에서 `wsl --install -d Ubuntu`로 WSL Ubuntu 설치 → VSCode 터미널을 Ubuntu(WSL)로 전환 후 정상 동작

![PowerShell 오류](docs/images/ts-01-powershell-ls.png)
![WSL 미설치](docs/images/ts-01-wsl-not-installed.png)
![Ubuntu 홈 진입](docs/images/ts-01-wsl-ubuntu-home.png)

### 7-2. 같은 이름의 컨테이너 생성 시 Conflict 오류

- **문제**: 볼륨 실습을 다시 실행할 때 `docker run --name vol-test2 ...`에서 `Conflict. The container name "/vol-test2" is already in use` 오류
- **원인 가설**: 이전 실습에서 만든 `vol-test2` 컨테이너가 아직 남아 있을 것
- **확인**: `docker ps -a`에서 `vol-test2`가 `Up` 상태로 존재함을 확인
- **해결**: 기존 컨테이너를 그대로 사용해 `docker exec vol-test2 cat /data/hello.txt`로 검증. 새로 만들려면 `docker rm -f vol-test2` 후 다시 실행

![컨테이너 이름 충돌](docs/images/ts-02-container-name-conflict.png)

### 7-3. VSCode에서 `wsl.localhost` 호스트 경고

- **문제**: WSL 터미널에서 `code .` 실행 시 "허용된 호스트 목록에서 'wsl.localhost' 호스트를 찾을 수 없습니다" 경고
- **원인 가설**: VSCode에 WSL 확장이 없어 Ubuntu 폴더를 Windows 네트워크 경로(`\\wsl.localhost\...`)로 우회해서 열려고 함
- **확인**: 확장 목록에 Microsoft WSL 확장이 설치되어 있지 않음
- **해결**: 경고창은 취소 → WSL 확장(Microsoft) 설치 → `code .` 재실행 → 왼쪽 아래 `WSL: Ubuntu` 표시와 함께 정상 연결

![wsl.localhost 경고](docs/images/ts-03-vscode-wsl-host-warning.png)
![WSL 확장 설치](docs/images/ts-03-wsl-extension.png)

### 7-4. 스크린샷이 저장소 폴더에 보이지 않음 (Windows 경로 vs Ubuntu 경로)

- **문제**: 이미지를 `docs/images`에 복사했는데 Ubuntu에서 `ls docs/images` 결과가 비어 있음
- **원인 가설**: 같은 이름의 폴더가 Windows와 Ubuntu에 따로 있어서 다른 곳에 복사했을 것
- **확인**: 파일 탐색기 경로가 `C:\Users\fdyoung68559\codyssey\workstation\docs\images`(Windows)였고, 실제 저장소는 `/home/fdyoung68559/codyssey/workstation`(Ubuntu)
- **해결**: Ubuntu에서 Windows C 드라이브는 `/mnt/c`로 보이므로 `cp /mnt/c/Users/fdyoung68559/codyssey/workstation/docs/images/*.png docs/images/`로 복사

### 7-5. Git 사용자 이름에 줄바꿈이 함께 저장됨

- **문제**: `git config --list`에서 `user.name` 다음에 빈 줄이 출력됨
- **원인 가설**: 이름 입력 중 닫는 따옴표 전에 Enter가 눌려 줄바꿈 문자가 함께 저장되었을 것
- **확인**: `user.name=fdyoung9-a11y` 아래 빈 줄 존재
- **해결**: `git config --global user.name "fdyoung9-a11y"`를 한 줄로 다시 실행해 덮어씀

### 7-6. 포트 충돌 (port is already allocated)

- **문제**: 이미 8080을 쓰는 컨테이너가 있는 상태에서 `docker run -p 8080:80 ...` 실행 시 `Bind for 0.0.0.0:8080 failed: port is already allocated` 오류
- **원인 가설**: 다른 컨테이너(또는 프로세스)가 호스트의 8080 포트를 이미 점유하고 있을 것
- **확인**: 포트를 점유한 대상을 두 가지 방법으로 진단

```bash
# 문제 재현
$ docker run -d -p 8080:80 --name port-test nginx:alpine
docker: Error response from daemon: failed to set up container networking: ...
Bind for 0.0.0.0:8080 failed: port is already allocated

# 진단 1: 8080을 공개(publish) 중인 컨테이너 찾기
$ docker ps --filter "publish=8080"
CONTAINER ID   IMAGE        ...   STATUS          PORTS                                     NAMES
c11969c61554   my-web:1.0   ...   Up 10 seconds   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   my-web-8080

# 진단 2: 리눅스에서 8080 포트가 대기(LISTEN) 중인지 확인
$ ss -ltn | grep 8080
LISTEN 0      4096               *:8080            *:*
```

- **해결**: 상황에 따라 두 가지 방법 중 선택

```bash
# 방법 A: 충돌을 피해 다른 호스트 포트 사용
$ docker rm port-test                      # 시작 실패한 컨테이너 정리
$ docker run -d -p 8083:80 --name port-test nginx:alpine

# 방법 B: 기존 점유 컨테이너를 멈춰 포트 해제 후 재실행
$ docker rm -f port-test
$ docker stop my-web-8080
$ docker ps --filter "publish=8080"        # 결과 없음 → 점유 컨테이너 없음
$ ss -ltn | grep 8080                      # 결과 없음 → 포트 해제 확인
$ docker run -d -p 8080:80 --name port-test nginx:alpine
$ curl -s http://localhost:8080 | head -4
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>

# 원래 상태로 복구
$ docker rm -f port-test
$ docker start my-web-8080
```

- **참고**: Docker가 아닌 일반 프로세스가 포트를 점유한 경우에는 `sudo ss -ltnp | grep 8080`으로 프로세스 이름·PID를 확인하고, 해당 프로그램을 종료하거나 `kill <PID>`로 해제한다. (Windows 쪽 프로그램이 점유한 경우 PowerShell에서 `netstat -ano | findstr :8080`으로 PID 확인)

![포트 충돌 진단](docs/images/ts-04-port-conflict-diagnose.png)
![포트 해제 후 재실행](docs/images/ts-04-port-release.png)

---

## 8. 개념 정리

### 절대 경로와 상대 경로

- **절대 경로**는 루트(`/`)부터 시작하는 전체 주소로, 현재 위치와 관계없이 항상 같은 곳을 가리킵니다. 예: `/home/fdyoung68559/codyssey/workstation/hello.txt`
- **상대 경로**는 현재 위치를 기준으로 한 주소입니다. 예: `~/codyssey/workstation`에서 `cat hello.txt`, `cd ..`(한 단계 위), `./`(현재 폴더)
- 바인드 마운트(`-v $(pwd)/bind-site:...`)처럼 정확한 위치가 필요한 곳에서는 절대 경로를 사용했습니다.

### 파일 권한 (r/w/x, 755, 644)

- `r`(읽기)=4, `w`(쓰기)=2, `x`(실행, 디렉토리는 진입)=1이며, **소유자/그룹/기타** 세 자리로 각각 더해 표기합니다.
- `755` = 7(rwx) / 5(r-x) / 5(r-x) → 실행 파일·디렉토리에 주로 사용
- `644` = 6(rw-) / 4(r--) / 4(r--) → 일반 파일에 주로 사용

### 커스텀 이미지

- 이미지는 실행 환경을 묶은 읽기 전용 설계도이고, 컨테이너는 그 이미지를 실행한 인스턴스입니다.
- 기존 `nginx:alpine` 이미지를 `FROM`으로 가져오고, `COPY`로 내 콘텐츠만 바꿔 `my-web:1.0`을 만들었습니다. 같은 이미지로 컨테이너를 여러 개 띄워도 동일하게 재현됩니다.

### 포트 매핑이 필요한 이유

- 컨테이너는 호스트와 분리된 네트워크 공간에서 실행되어, 컨테이너 내부 포트(80)에 호스트가 직접 접근할 수 없습니다.
- `-p 호스트포트:컨테이너포트`로 연결해야 외부에서 접속할 수 있고, 호스트 포트만 다르게 하면 같은 이미지를 여러 개 동시에 띄울 수 있습니다(8080, 8081).

### Docker 볼륨 (영속 데이터)

- 컨테이너 내부에 저장한 데이터는 컨테이너를 삭제하면 함께 사라집니다.
- 볼륨은 Docker가 관리하는 별도 저장 공간이라, 컨테이너를 삭제해도 남고 새 컨테이너에 다시 연결해 쓸 수 있습니다.
- 바인드 마운트는 내가 지정한 호스트 폴더를 연결하므로 개발 중 파일 수정을 바로 반영할 때 유용합니다.

### Git과 GitHub의 역할 차이

| | Git | GitHub |
|---|---|---|
| 정체 | 버전 관리 프로그램 | Git 저장소 호스팅 서비스 |
| 위치 | 내 컴퓨터(로컬) | 인터넷(원격) |
| 역할 | 변경 이력 기록(`commit`), 되돌리기 | 저장소 공유, 협업, 공개(`push`/`pull`) |

---

## 9. 보안 및 개인정보

- Git 설정의 이메일은 문서와 스크린샷에서 마스킹했습니다.
- GitHub 인증은 VSCode의 GitHub 로그인으로 처리해 토큰·비밀번호를 터미널이나 문서에 남기지 않았습니다.
- `.gitignore`에 `.env`, `*.log`를 등록해 민감정보 파일이 실수로 올라가지 않도록 했습니다.

---

## 10. 보너스 과제

| 과제 | 내용 | 결과 |
|---|---|---|
| B1. Docker Compose 기초 | `docker run` 옵션을 `docker-compose.yml`로 문서화, 단일 서비스 실행 | `localhost:8090` 접속 성공 |
| B2. Compose 운영 명령 | `up`, `ps`, `logs`, `down`으로 상태 확인 루틴 구성 | 종료 후 재실행 정상 |
| B3. 멀티 컨테이너 | 웹 서버(`web`) + 보조 서비스(`checker`), 서비스 이름으로 통신 | `http://web` 응답 수신 |
| B4. 환경 변수 | `.env`로 호스트 포트·nginx 포트·실행 모드 분리 | 값만 바꿔 9090/8000/prod로 전환 |
| B5. GitHub SSH 키 | ed25519 키 생성·등록, 원격 주소를 SSH로 변경 | 로그인 없이 push 성공 |

### 10-1. Docker Compose 기초 (단일 서비스)

**배움 포인트**: 매번 기억해서 입력하던 `docker run -d -p 8080:80 --name ... my-web:1.0` 명령이 파일로 남아, 누구나 `docker compose up` 한 줄로 같은 환경을 재현할 수 있고 설정 변경도 Git으로 기록된다.

```yaml
# docker-compose.yml (B1 시점)
services:
  web:
    build: .                  # 현재 폴더의 Dockerfile로 이미지 빌드
    image: my-web:compose
    container_name: compose-web
    ports:
      - "8090:80"
```

```bash
$ docker compose version
Docker Compose version v5.6.1

$ docker compose up -d --build
 => CACHED [2/2] COPY site/ /usr/share/nginx/html/
 ✔ Image my-web:compose          Built
 ✔ Network workstation_default   Created
 ✔ Container compose-web         Started

$ docker compose ps
NAME          IMAGE            SERVICE   STATUS         PORTS
compose-web   my-web:compose   web       Up 18 seconds  0.0.0.0:8090->80/tcp

$ curl http://localhost:8090
  <h1>Hello Codyssey!</h1>
```

- `CACHED`: 이전 `my-web:1.0` 빌드와 같은 단계라 다시 실행하지 않고 저장된 결과를 재사용
- `Network workstation_default Created`: Compose가 서비스 전용 네트워크를 자동 생성

![Compose 실행](docs/images/b1-compose-up.png)
![브라우저 8090](docs/images/b1-browser-8090.png)

### 10-2. Compose 운영 명령 (상태 확인 루틴)

```bash
$ docker compose logs --tail 5 web
compose-web | 172.18.0.1 - - [...] "GET / HTTP/1.1" 200 209 "-" "Mozilla/5.0 ... Chrome/156.0.0.0 ..."
compose-web | [error] ... open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory)
compose-web | 172.18.0.1 - - [...] "GET /favicon.ico HTTP/1.1" 404 555 ...
compose-web | 172.18.0.1 - - [...] "GET / HTTP/1.1" 200 209 "-" "curl/8.18.0"
compose-web | 172.18.0.1 - - [...] "GET / HTTP/1.1" 200 209 "-" "curl/8.18.0"

$ docker compose down
 ✔ Container compose-web        Removed
 ✔ Network workstation_default  Removed
$ docker compose ps                  # 목록 비어 있음

$ docker compose up -d
 ✔ Network workstation_default  Created
 ✔ Container compose-web        Started
$ curl -s http://localhost:8090 | grep h1
  <h1>Hello Codyssey!</h1>
```

| 상황 | 명령 |
|---|---|
| 실행 | `docker compose up -d` |
| 살아 있나? | `docker compose ps` |
| 무슨 일이 있었나? | `docker compose logs --tail N 서비스명` |
| 완전히 정리 (컨테이너·네트워크 삭제) | `docker compose down` |

- 로그의 User-Agent로 접속 주체(브라우저 / curl)를 구분할 수 있다.
- `favicon.ico` 404는 브라우저가 탭 아이콘을 자동 요청한 것으로, 페이지 동작과 무관하다.

![Compose 운영 명령](docs/images/b2-compose-ops.png)

### 10-3. 멀티 컨테이너와 서비스 디스커버리

**배움 포인트**: 같은 Compose 파일의 서비스는 하나의 네트워크에 들어가며, 그 안에서는 IP 대신 **서비스 이름**으로 서로를 찾는다.

```yaml
  checker:                       # 보조 서비스: 5초마다 web에 접속
    image: curlimages/curl:8.11.1
    container_name: compose-checker
    depends_on:
      - web
    entrypoint: ["sh", "-c"]
    command:
      - |
        while true; do
          echo "[$(date +%T)] $(curl -s http://web | grep -o '<h1>.*</h1>')"
          sleep 5
        done
```

```bash
$ docker compose ps
compose-checker   curlimages/curl:8.11.1   checker   Up 2 seconds
compose-web       my-web:compose           web       Up 3 minutes   0.0.0.0:8090->80/tcp

$ docker compose logs --tail 3 checker
compose-checker | [02:33:37] <h1>Hello Codyssey!</h1>
compose-checker | [02:33:42] <h1>Hello Codyssey!</h1>
compose-checker | [02:33:47] <h1>Hello Codyssey!</h1>

$ docker network inspect workstation_default --format '{{range .Containers}}{{.Name}} {{end}}'
compose-checker compose-web

$ curl -s --max-time 3 http://web || echo "호스트에서는 web 이름을 찾을 수 없음"
호스트에서는 web 이름을 찾을 수 없음
$ curl -s http://localhost:8090 | grep h1
  <h1>Hello Codyssey!</h1>
```

| 접속하는 곳 | 주소 | 결과 | 이유 |
|---|---|---|---|
| `checker` 컨테이너 안 | `http://web` | 성공 | 같은 Compose 네트워크라 서비스 이름으로 찾음 |
| 호스트(Ubuntu) | `http://web` | 실패 | 네트워크 바깥이라 `web` 이름을 모름 |
| 호스트(Ubuntu) | `http://localhost:8090` | 성공 | 포트 매핑으로 연결 |

- `checker`는 외부 접속이 필요 없어 `ports`를 열지 않았다.
- `up` 시 설정이 바뀌지 않은 `compose-web`은 `Running`(유지), 새 서비스만 `Started`: Compose는 변경된 서비스만 다시 만든다.

![멀티 컨테이너](docs/images/b3-multi-container.png)

### 10-4. 환경 변수로 설정과 코드 분리

**배움 포인트**: 환경마다 달라지는 값(포트, 모드)을 `.env`로 빼 두면, 코드 파일은 그대로 두고 값만 바꿔 다르게 실행할 수 있다.

```bash
# .env (Git에 올리지 않음) / .env.example (Git에 올리는 예시)
WEB_PORT=8090      # 호스트 포트
NGINX_PORT=80      # 컨테이너 안 nginx 포트
APP_ENV=dev        # 실행 모드
```

```yaml
# docker-compose.yml (web 서비스)
    environment:
      APP_ENV: ${APP_ENV:-dev}           # 값이 없으면 dev
      NGINX_PORT: ${NGINX_PORT:-80}
    volumes:
      - ./nginx:/etc/nginx/templates:ro  # nginx 템플릿 연결
    ports:
      - "${WEB_PORT:-8090}:${NGINX_PORT:-80}"
```

```nginx
# nginx/default.conf.template (컨테이너 시작 시 ${변수}가 실제 값으로 치환됨)
server {
    listen ${NGINX_PORT};
    location / { root /usr/share/nginx/html; index index.html; }
    location /env {
        default_type text/plain;
        return 200 "APP_ENV=${APP_ENV} NGINX_PORT=${NGINX_PORT}\n";
    }
}
```

**기본값으로 실행**

```bash
$ docker compose config | grep -E "APP_ENV|NGINX_PORT|published|target"
      APP_ENV: dev
      NGINX_PORT: "80"
        target: 80
        published: "8090"
$ curl http://localhost:8090/env
APP_ENV=dev NGINX_PORT=80
```

![환경 변수 기본값](docs/images/b4-env-default.png)

**`.env`가 Git에 올라가지 않는 것 확인**

```bash
$ git status
Untracked files:
        .env.example
        nginx/
# .env는 .gitignore에 등록되어 있어 목록에 나타나지 않음
```

실제 서비스에서 `.env`에는 비밀번호·API 키가 들어가므로 저장소에 올리지 않고, 필요한 변수 목록만 `.env.example`로 공유한다.

![gitignore 확인](docs/images/b4-env-gitignore.png)

**`.env` 값만 바꿔서 재실행**

```bash
$ sed -i 's/^WEB_PORT=.*/WEB_PORT=9090/; s/^NGINX_PORT=.*/NGINX_PORT=8000/; s/^APP_ENV=.*/APP_ENV=prod/' .env
$ docker compose up -d
$ docker compose ps
compose-web   ...   0.0.0.0:9090->8000/tcp
$ curl http://localhost:9090/env
APP_ENV=prod NGINX_PORT=8000
$ curl -s --max-time 3 http://localhost:8090 || echo "8090은 더 이상 사용하지 않음"
8090은 더 이상 사용하지 않음
$ docker compose logs --tail 2 checker
compose-checker | [02:38:56] <h1>Hello Codyssey!</h1>     # checker도 web:8000으로 자동 접속

# 원래 값으로 복구
$ cp .env.example .env
$ docker compose up -d
$ curl http://localhost:8090/env
APP_ENV=dev NGINX_PORT=80
```

![환경 변수 변경](docs/images/b4-env-prod.png)

### 10-5. GitHub SSH 키 설정

**배움 포인트**: SSH는 키 한 쌍으로 인증한다. 개인 키는 내 컴퓨터에만 두고, 공개 키만 GitHub에 등록한다.

| | HTTPS | SSH |
|---|---|---|
| 인증 | 계정 로그인 / 토큰 | 키 파일 쌍 |
| 원격 주소 | `https://github.com/...` | `git@github.com:...` |
| 특징 | 설정이 간단 | 한 번 등록하면 push 때 로그인·토큰 입력 없음 |

```bash
$ ssh-keygen -t ed25519 -C "fdyoung9-a11y-wsl"
$ ls -la ~/.ssh
drwx------  2 fdyoung68559 fdyoung68559 4096 Nov  8 11:41 .
-rw-------  1 fdyoung68559 fdyoung68559  411 Nov  8 11:41 id_ed25519       # 개인 키: 600 (나만 접근)
-rw-r--r--  1 fdyoung68559 fdyoung68559   99 Nov  8 11:41 id_ed25519.pub   # 공개 키: 644

$ ssh -T git@github.com
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added 'github.com' (ED25519) to the list of known hosts.
Hi fdyoung6-codyssey! You've successfully authenticated, but GitHub does not provide shell access.

$ git remote set-url origin git@github.com:fdyoung6-codyssey/1-1_mywork.git
$ git remote -v
origin  git@github.com:fdyoung6-codyssey/1-1_mywork.git (fetch)
origin  git@github.com:fdyoung6-codyssey/1-1_mywork.git (push)

$ git push
To github.com:fdyoung6-codyssey/1-1_mywork.git
   9be65d5..72ddabb  main -> main
```

- 개인 키는 자동으로 600 권한으로 생성된다. 권한이 너무 열려 있으면 SSH가 키 사용을 거부한다.
- 공개 키 내용은 문서와 스크린샷에서 가렸다. 개인 키(`id_ed25519`)는 출력하지 않았다.

![SSH push](docs/images/b5-ssh-push.png)
![GitHub SSH 키 등록](docs/images/b5-github-ssh-key.png)

### 10-6. 트러블슈팅: Ubuntu에서 `docker` 명령을 찾을 수 없음

- **문제**: 컴퓨터를 다시 켠 뒤 `docker compose version` 실행 시 `The command 'docker' could not be found in this WSL 2 distro` 오류
- **원인 가설**: Docker Desktop이 실행되지 않았거나, Ubuntu와의 WSL 연결이 풀렸을 것
- **확인**: Docker Desktop 설정에서 `Start Docker Desktop when you sign in to your computer`가 꺼져 있어 자동 실행되지 않았음을 확인
- **해결**: Docker Desktop 실행 → `Engine running` 확인 → `Settings → WSL integration`에서 Ubuntu 연결을 다시 켜고 Apply → VSCode 터미널 재시작 후 `docker --version` 정상 출력

```bash
$ docker --version
Docker version 29.9.2, build a82e528
$ docker compose version
Docker Compose version v5.6.1
```

![docker 명령 없음](docs/images/ts-05-docker-not-found.png)
![Docker Desktop 설정](docs/images/ts-05-docker-settings.png)
![복구 후](docs/images/ts-05-docker-fixed.png)
