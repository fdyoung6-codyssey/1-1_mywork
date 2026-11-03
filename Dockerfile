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
