# 내 컴퓨터에 개발자용 '작업실' 꾸미기

코디세이 올인원 1기 입학연수 1-1 미션. Windows에 WSL2 Ubuntu를 설치하고 터미널, Docker, Git/GitHub를 세팅한 뒤 실행 결과로 검증한 기록입니다.

### 프로젝트 개요

| 목표 | 수행 내용 |
|---|---|
| 터미널 기본기 | 작업 폴더 구성, 파일 생성·복사·이동·삭제, 권한(`chmod`) 변경 |
| Docker 운영 | 설치 점검, 이미지·컨테이너 실행/중지/로그/리소스 확인 |
| 커스텀 이미지 | `nginx:alpine` 기반 Dockerfile로 내 웹 페이지 이미지 빌드 |
| 네트워크·스토리지 | 포트 매핑 접속, 바인드 마운트 반영, 볼륨 영속성 검증 |
| 버전 관리·협업 | Git 설정, GitHub 연동, VSCode 로그인, SSH push |

## 1. 실행 환경

| 항목 | 내용 |
|---|---|
| OS | Windows + WSL2 (Ubuntu 26.04.1 LTS) |
| Shell / 터미널 | bash / VSCode 통합 터미널 (WSL: Ubuntu) |
| Docker | 29.9.2 (Docker Desktop 4.97.0), Compose v5.6.1 |
| Git | 2.53.0 |

**재현 시 주의**: Windows에서는 PowerShell이 아닌 WSL Ubuntu 터미널에서 실행합니다. Docker Desktop의 `Settings → Resources → WSL integration`에서 Ubuntu를 켜야 `docker` 명령이 됩니다. macOS는 OrbStack으로 같은 명령을 쓸 수 있습니다. `/home/fdyoung68559`는 각자의 `~`로 바꿔 읽으면 됩니다.

## 2. 수행 체크리스트와 검증 방법

| 항목 | 확인 방법 | 결과 | 로그 |
|---|---|---|---|
| [x] 터미널 조작 | `pwd` `ls -la` `cp` `mv` `rm` | 생성·복사·이동·삭제 확인 | [3-1](#3-1-터미널-조작) |
| [x] 권한 변경 | `stat`, `chmod` | 파일 644→600, 폴더 755→700 | [3-2](#3-2-권한-변경) |
| [x] Docker 점검 | `docker --version`, `docker info` | 29.9.2, Server 정상 | [3-3](#3-3-docker-점검과-운영-명령) |
| [x] 운영 명령 | `images` `ps -a` `logs` `stats` `stop` | 로그·리소스 확인 | [3-3](#3-3-docker-점검과-운영-명령) |
| [x] 컨테이너 실습 | hello-world, ubuntu 진입, attach/exec | exec 후 Up, attach 후 Exited | [3-4](#3-4-컨테이너-실습) |
| [x] 커스텀 이미지 | `docker build` | `my-web:1.0` 생성 | [3-5](#3-5-커스텀-이미지와-포트-매핑) |
| [x] 포트 매핑 | `-p 8080:80`, `-p 8081:80` | 두 포트 모두 접속 | [3-5](#3-5-커스텀-이미지와-포트-매핑) |
| [x] 바인드 마운트 | 호스트에서 `sed`로 수정 | 재시작 없이 반영 | [3-6](#3-6-바인드-마운트와-볼륨) |
| [x] 볼륨 | 컨테이너 삭제 후 재연결 | 데이터 유지 | [3-6](#3-6-바인드-마운트와-볼륨) |
| [x] Git·GitHub | `git config --list`, `git push` | 설정 3줄, push 완료 | [3-7](#3-7-git과-github) |
| [x] 보너스 5개 | Compose, 환경 변수, SSH | 모두 동작 | [5](#5-보너스-과제) |

## 3. 수행 로그

### 3-1. 터미널 조작

```bash
$ pwd
/home/fdyoung68559
$ ls -la                                   # 숨김 파일 포함
drwxr-x--- 4 fdyoung68559 fdyoung68559 4096 Nov  3 13:51 .
-rw-r--r-- 1 fdyoung68559 fdyoung68559 3771 Nov  3 13:49 .bashrc
...
$ mkdir -p codyssey/workstation && cd codyssey/workstation
$ touch empty.txt                          # 빈 파일
$ echo "Hello Codyssey" > hello.txt
$ cat hello.txt
Hello Codyssey
$ cp hello.txt hello_copy.txt              # 복사
$ mkdir backup && mv hello_copy.txt backup/                     # 이동
$ mv backup/hello_copy.txt backup/hello_backup.txt              # 이름 변경
$ rm empty.txt                             # 삭제
$ ls -la
drwxr-xr-x 2 fdyoung68559 fdyoung68559 4096 Nov  3 13:58 backup
-rw-r--r-- 1 fdyoung68559 fdyoung68559   15 Nov  3 13:58 hello.txt
```

### 3-2. 권한 변경

```bash
$ stat -c '%a %A %n' hello.txt  →  644 -rw-r--r-- hello.txt
$ chmod 600 hello.txt
$ stat -c '%a %A %n' hello.txt  →  600 -rw------- hello.txt

$ stat -c '%a %A %n' backup     →  755 drwxr-xr-x backup
$ chmod 700 backup
$ stat -c '%a %A %n' backup     →  700 drwx------ backup
```

### 3-3. Docker 점검과 운영 명령

```bash
$ docker --version
Docker version 29.9.2, build a82e528
$ docker info
Server:
 Containers: 0
 Server Version: 29.9.2
 Kernel Version: 6.18.54.1-microsoft-standard-WSL2
 Operating System: Docker Desktop
...

$ docker run -d --name log-test ubuntu bash -c 'while true; do echo "tick $(date +%T)"; sleep 2; done'
$ docker logs --tail 3 log-test
tick 05:20:02
tick 05:20:04
tick 05:20:06
$ docker stats --no-stream
NAME       CPU %   MEM USAGE / LIMIT
log-test   0.62%   3.207MiB / 15.25GiB
$ docker stop log-test
$ docker ps -a
... log-test   Exited (137)        # 종료 신호에 반응하지 않아 강제 종료됨
```

### 3-4. 컨테이너 실습

```bash
$ docker run hello-world
Hello from Docker!
$ docker images
hello-world:latest   c567b231f656   25.9kB
$ docker ps -a
0be6de0f97aa   hello-world   "/hello"   Exited (0)   inspiring_napier

$ docker run -it --name my-ubuntu ubuntu bash
root@5fa7fdb5d2a3:/# ls
bin  boot  dev  etc  home  lib  ...  usr  var
root@5fa7fdb5d2a3:/# echo "Hello from container"
Hello from container
root@5fa7fdb5d2a3:/# exit

$ docker start my-ubuntu
$ docker exec -it my-ubuntu bash      # → exit
$ docker ps
... my-ubuntu   Up 24 seconds          # exec: 새 bash였으므로 컨테이너 유지
$ docker attach my-ubuntu             # → exit
$ docker ps -a
... my-ubuntu   Exited (0)             # attach: 메인 bash가 끝나 컨테이너 종료
```

### 3-5. 커스텀 이미지와 포트 매핑

방식 (A) 웹 서버 베이스 이미지 활용.

```dockerfile
FROM nginx:alpine                                   # 공식 웹 서버 이미지 재사용 (가벼운 alpine)
LABEL org.opencontainers.image.title="codyssey-web" # 이미지 식별용 이름표
ENV APP_ENV=dev                                     # 실행 환경 표시
COPY site/ /usr/share/nginx/html/                   # 기본 페이지를 내 index.html로 교체
EXPOSE 80                                           # 사용하는 포트 문서화
```

```bash
$ docker build -t my-web:1.0 .
[+] Building 4.9s (7/7) FINISHED
 => [2/2] COPY site/ /usr/share/nginx/html/
 => => naming to docker.io/library/my-web:1.0

$ docker run -d -p 8080:80 --name my-web-8080 my-web:1.0
$ docker run -d -p 8081:80 --name my-web-8081 my-web:1.0
$ docker ps
my-web:1.0   Up   0.0.0.0:8081->80/tcp   my-web-8081
my-web:1.0   Up   0.0.0.0:8080->80/tcp   my-web-8080
$ curl http://localhost:8080
  <h1>Hello Codyssey!</h1>
```

| 브라우저 8080 | 브라우저 8081 |
|---|---|
| ![8080](docs/images/13-browser-8080.png) | ![8081](docs/images/14-browser-8081.png) |

### 3-6. 바인드 마운트와 볼륨

```bash
# 바인드 마운트: 호스트 폴더를 컨테이너에 연결
$ docker run -d -p 8082:80 --name my-web-bind -v $(pwd)/bind-site:/usr/share/nginx/html nginx:alpine
$ curl http://localhost:8082                    # 변경 전
  <h1>Hello Codyssey!</h1>
$ sed -i 's/Hello Codyssey!/Hello Bind Mount! (수정됨)/' bind-site/index.html
$ curl http://localhost:8082                    # 변경 후 (재시작 없음)
  <h1>Hello Bind Mount! (수정됨)</h1>

# 볼륨: 컨테이너를 지워도 데이터 유지
$ docker volume create mydata
$ docker run -d --name vol-test1 -v mydata:/data ubuntu sleep infinity
$ docker exec vol-test1 sh -c "echo 'persistent data test' > /data/hello.txt"
$ docker rm -f vol-test1
$ docker run -d --name vol-test2 -v mydata:/data ubuntu sleep infinity
$ docker exec vol-test2 cat /data/hello.txt
persistent data test
```

| 바인드 마운트 변경 전 | 변경 후 |
|---|---|
| ![전](docs/images/16-bind-before-browser.png) | ![후](docs/images/18-bind-after-browser.png) |

### 3-7. Git과 GitHub

```bash
$ git config --list
user.name=fdyoung9-a11y
user.email=(마스킹)
init.defaultbranch=main

$ git init && git add . && git commit -m "feat: 터미널 실습 파일과 Dockerfile 기반 커스텀 웹 서버 추가"
[main (root-commit) 3ff5b07] ...
$ git remote -v
origin  git@github.com:fdyoung6-codyssey/1-1_mywork.git (push)
$ git push
To github.com:fdyoung6-codyssey/1-1_mywork.git
   9be65d5..72ddabb  main -> main
```

![VSCode GitHub 로그인](docs/images/25-vscode-github-login.png)

<details>
<summary>나머지 스크린샷 보기</summary>

![터미널](docs/images/01-terminal-basic.png)
![파일 조작](docs/images/02-file-ops.png)
![권한](docs/images/03-permission.png)
![Docker Desktop](docs/images/04-docker-desktop.png)
![docker version](docs/images/05-docker-version.png)
![docker info](docs/images/06-docker-info-server.png)
![hello-world](docs/images/07-hello-world.png)
![ubuntu](docs/images/08-ubuntu-container.png)
![attach exec](docs/images/09-attach-exec.png)
![logs stats](docs/images/10-logs-stats.png)
![build](docs/images/11-docker-build.png)
![port curl](docs/images/12-port-curl.png)
![bind 터미널 전](docs/images/15-bind-before-terminal.png)
![bind 터미널 후](docs/images/17-bind-after-terminal.png)
![volume](docs/images/19-volume.png)
![git config](docs/images/20-git-config.png)
![repo 생성](docs/images/21-github-repo-created.png)
![git init](docs/images/22-git-init-commit.png)
![VSCode WSL](docs/images/23-vscode-wsl-workstation.png)
![git push](docs/images/24-git-push.png)
![GitHub 저장소](docs/images/26-github-repo-files.png)

</details>

## 4. 트러블슈팅

| 문제 | 원인 | 해결 |
|---|---|---|
| PowerShell에서 `ls -la` 오류 | PowerShell은 리눅스 터미널이 아님 | `wsl --install -d Ubuntu` 후 WSL 터미널 사용 |
| `vol-test2` 이름 Conflict | 같은 이름 컨테이너가 이미 있음 | 기존 것 사용 또는 `docker rm -f` |
| VSCode `wsl.localhost` 경고 | WSL 확장 없음 | Microsoft WSL 확장 설치 후 `code .` |
| 이미지가 `docs/images`에 없음 | Windows(`C:\Users\...`)와 Ubuntu(`/home/...`)는 다른 경로 | `cp /mnt/c/Users/.../*.png docs/images/` |
| `user.name` 뒤 빈 줄 | 따옴표를 닫기 전 Enter | 한 줄로 다시 설정 |
| 재부팅 후 `docker` 명령 없음 | Docker Desktop 미실행, WSL 연동 해제 | 실행 후 WSL integration 다시 켜기 |
| `port is already allocated` | 8080을 다른 컨테이너가 점유 | 아래 참고 |

**포트 충돌 진단과 해제**

```bash
$ docker run -d -p 8080:80 --name port-test nginx:alpine
Bind for 0.0.0.0:8080 failed: port is already allocated

$ docker ps --filter "publish=8080"        # 점유한 컨테이너 찾기
c11969c61554   my-web:1.0   0.0.0.0:8080->80/tcp   my-web-8080
$ ss -ltn | grep 8080                      # 대기 중인 포트 확인
LISTEN 0  4096  *:8080  *:*

$ docker rm -f port-test
$ docker stop my-web-8080                  # 포트 비우기 (또는 -p 8083:80 처럼 다른 포트 사용)
$ ss -ltn | grep 8080                      # 결과 없음 → 해제됨
$ docker run -d -p 8080:80 --name port-test nginx:alpine
$ curl -s http://localhost:8080 | head -4
<title>Welcome to nginx!</title>
```

Docker가 아닌 프로그램이 점유했다면 `sudo ss -ltnp | grep 8080`으로 PID를 확인해 종료합니다.

<details>
<summary>트러블슈팅 스크린샷 보기</summary>

![PowerShell 오류](docs/images/ts-01-powershell-ls.png)
![WSL 미설치](docs/images/ts-01-wsl-not-installed.png)
![Ubuntu 홈](docs/images/ts-01-wsl-ubuntu-home.png)
![이름 충돌](docs/images/ts-02-container-name-conflict.png)
![wsl.localhost](docs/images/ts-03-vscode-wsl-host-warning.png)
![WSL 확장](docs/images/ts-03-wsl-extension.png)
![포트 충돌](docs/images/ts-04-port-conflict-diagnose.png)
![포트 해제](docs/images/ts-04-port-release.png)
![docker 없음](docs/images/ts-05-docker-not-found.png)
![Docker 설정](docs/images/ts-05-docker-settings.png)
![복구](docs/images/ts-05-docker-fixed.png)

</details>

## 5. 보너스 과제

```bash
# B1·B2. Compose 기초와 운영 명령
$ docker compose up -d --build
 ✔ Network workstation_default  Created
 ✔ Container compose-web        Started
$ docker compose ps
compose-web   my-web:compose   Up   0.0.0.0:8090->80/tcp
$ docker compose down              # 컨테이너·네트워크 삭제 → up -d로 재실행

# B3. 멀티 컨테이너: checker가 서비스 이름 web으로 접속
$ docker compose logs --tail 1 checker
compose-checker | [02:33:47] <h1>Hello Codyssey!</h1>
$ curl -s --max-time 3 http://web || echo "호스트에서는 web 이름을 찾을 수 없음"
호스트에서는 web 이름을 찾을 수 없음

# B4. 환경 변수: .env 값만 바꿔 재실행 (.env는 Git 제외, .env.example만 공유)
$ curl http://localhost:8090/env
APP_ENV=dev NGINX_PORT=80
$ sed -i 's/^WEB_PORT=.*/WEB_PORT=9090/; s/^NGINX_PORT=.*/NGINX_PORT=8000/; s/^APP_ENV=.*/APP_ENV=prod/' .env
$ docker compose up -d
$ curl http://localhost:9090/env
APP_ENV=prod NGINX_PORT=8000

# B5. SSH 키: 개인 키는 600, 공개 키만 GitHub에 등록
$ ls -la ~/.ssh
-rw-------  1 fdyoung68559 fdyoung68559  411 Nov  8 11:41 id_ed25519
-rw-r--r--  1 fdyoung68559 fdyoung68559   99 Nov  8 11:41 id_ed25519.pub
$ ssh -T git@github.com
Hi fdyoung6-codyssey! You've successfully authenticated, but GitHub does not provide shell access.
```

<details>
<summary>보너스 스크린샷 보기</summary>

![Compose](docs/images/b1-compose-up.png)
![8090](docs/images/b1-browser-8090.png)
![운영 명령](docs/images/b2-compose-ops.png)
![멀티 컨테이너](docs/images/b3-multi-container.png)
![환경 변수 기본](docs/images/b4-env-default.png)
![gitignore](docs/images/b4-env-gitignore.png)
![환경 변수 변경](docs/images/b4-env-prod.png)
![SSH push](docs/images/b5-ssh-push.png)
![SSH 키](docs/images/b5-github-ssh-key.png)

</details>

## 6. 개념 정리

- **절대 vs 상대 경로**: 절대 경로는 `/`부터 적은 전체 주소라 어디서든 같고, 상대 경로는 현재 위치(`.`, `..`) 기준입니다.
- **권한 755·644**: 소유자/그룹/기타마다 r=4, w=2, x=1을 더한 값. 755 = `rwxr-xr-x`(폴더·실행 파일), 644 = `rw-r--r--`(일반 파일).
- **커스텀 이미지**: 공식 이미지를 `FROM`으로 가져와 필요한 부분만 추가합니다. 이미지는 설계도, 컨테이너는 실행한 것.
- **포트 매핑**: 컨테이너는 분리된 네트워크에서 돌기 때문에 `-p 호스트:컨테이너`로 연결해야 밖에서 접속됩니다.
- **볼륨**: 컨테이너를 지워도 남는 별도 저장 공간. 바인드 마운트는 내 폴더를 직접 연결해 수정이 바로 반영됩니다.
- **Git vs GitHub**: Git은 내 컴퓨터에서 이력을 기록하는 도구, GitHub은 그 기록을 올려 공유·협업하는 서비스입니다.

**보안**: 이메일과 SSH 공개 키는 가렸고, 개인 키·토큰은 문서에 남기지 않았습니다. `.gitignore`에 `.env`, `*.log`를 등록했습니다.
