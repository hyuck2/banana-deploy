# banana-deploy

## 빠른 시작

### 1. 이미지 빌드 & Kind 클러스터에 로드

```bash
# banana-org/ 루트에서 실행
docker build -f banana-deploy/app1/Dockerfile -t app1:v0.1.1 ./app1
kind load docker-image app1:v0.1.1 --name cluster-staging
```

### 2. 배포

```bash
cd banana-deploy/
bash helm-deploy.sh app1 prod
```

### 3. 브라우저 접속

port-forward가 필요합니다 (Kind 클러스터):

```bash
kubectl port-forward -n traefik svc/traefik 80:80
```

| URL | 대상 |
|-----|------|
| http://localhost/prod/app1/ | app1 prod |
| http://localhost/stage/app1/ | app1 stage |
| http://localhost/prod/app2/ | app2 prod |
| http://localhost/stage/app2/ | app2 stage |

---

## helm-deploy.sh — 배포

```bash
bash helm-deploy.sh <appname> <env>
```

| 인자 | 값 | 설명 |
|------|-----|------|
| appname | app1, app2 | 앱 이름 |
| env | prod, stage | 환경 |

예시:

```bash
bash helm-deploy.sh app1 prod    # app1을 prod에 배포
bash helm-deploy.sh app2 stage   # app2를 stage에 배포
```

내부적으로 실행되는 명령:

```bash
helm upgrade --install app1 ./common-chart \
  -f ./app1/common.yaml \
  -f ./app1/image/prod.yaml \
  --set env=prod \
  --namespace app1-prod --create-namespace
```

---

## rollback-helm-deploy.sh — 롤백

```bash
bash rollback-helm-deploy.sh <banana-deploy-tag>
```

태그 목록 확인:

```bash
git tag -l | sort
# app1-prod-v0.1.0
# app1-prod-v0.1.1
# app2-prod-v0.1.0
```

롤백 예시:

```bash
bash rollback-helm-deploy.sh app1-prod-v0.1.0
```

동작:
1. 태그에서 appname/env/version 파싱
2. 해당 태그 시점의 `image/{env}.yaml` 복원
3. 새 커밋 생성 (히스토리 보존)
4. `helm-deploy.sh` 자동 실행

---

## 전체 배포 플로우 (Kind 환경)

```
1. app1에서 버전 올리고 커밋
   cd app1/
   bash bump-version.sh patch
   git add version.txt && git commit -m "bump: v0.2.0"
   → post-commit hook이 banana-deploy/app1/image/prod.yaml 자동 업데이트

2. 이미지 빌드 & 로드
   cd ..   # banana-org/ 루트로 이동
   docker build -f banana-deploy/app1/Dockerfile -t app1:v0.2.0 ./app1
   kind load docker-image app1:v0.2.0 --name cluster-staging

3. 배포
   cd banana-deploy/
   bash helm-deploy.sh app1 prod
```

---

## 파일 구조

```
banana-deploy/
├── common-chart/           ← 공용 Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── app1/
│   ├── Dockerfile          ← docker build -f 로 사용
│   ├── common.yaml         ← image.repository, containerPort
│   └── image/
│       ├── prod.yaml       ← image.tag (post-commit hook이 자동 수정)
│       └── stage.yaml
├── app2/
│   ├── Dockerfile
│   ├── common.yaml
│   └── image/
│       ├── prod.yaml
│       └── stage.yaml
├── helm-deploy.sh
└── rollback-helm-deploy.sh
```
