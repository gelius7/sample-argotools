# valve-argotools

valve는 DevOps 툴체인을 구성하기 위해 다음과 같은 도구를 가지고 있습니다.
* valve-tools
  * CUI 기반 DevOps 툴체인 구성 도구
* valve-argotools
  * ArgoCD 기반 DevOps 툴체인 구성 도구 


## valve-argotools 개발 배경
CUI valve-tools는 사용이 간편하기 때문에 쉽게 데브옵스 툴체인을 구성할 수 있었습니다. 하지만 설치 환경에 따라서 다른 설정을 적용하려면 직접 valve-tools 코드를 수정해서 별도의 브랜치로 관리해야 합니다.

valve-argotools는 ArgoCD에서 바로 적용 가능한 구성 파일 저장소 입니다. 사용자는 valve-argotools 의 구성 파일을 복사해서 환경별로 라이브 저장소를 구성할 수 있습니다. 이를 통해 사용자는 손쉽게 GitOps 운영 환경을 구성할 수 있습니다. 

> <b>GitOps 란?</b> <br/>
> System development/management pattern: <br/>
> * GIT as the SINGLE source of truth of a system <br/>
> * GIT as the SINGLE place where we operate (create, change and destroy) ALL environment <br/>
> * ALL changes are observable/verifiable
> (출처: [luis_faceira](https://2018.agilept.org/speaker_luis_faceira.html))

> <b>[ArgoCD](https://argoproj.github.io/argo-cd/) 란?</b> <br/>
Argo CD is a declarative, GitOps continuous delivery tool for Kubernetes.
## valve-argotools 사용법
프로메테우스를 운영 환경에 배포하는 예제로 valve-argotools 사용법을 설명하겠습니다.
### 라이브 저장소 생성 및 설정 변경
* 라이브 인프라 및 애플리케이션 코드를 저장하기 위한 깃 프로젝트를 생성합니다.
  * 라이브 저장소 디렉토리 구조 예제
    * sample-dev-env  // 라이브 저장소 이름
      * infra  // 인프라 구성 코드(terraform, ...)
        * ...
      * app  // 애플리케이션 구성 코드
        * monitor // k8s 네임스페이스
          * grafana
          * ...
        * batch // k8s 네임스페이스
          * ...
        * kube-system // k8s 네임스페이스
          * ...
* 라이브 저장소에 valve-argotools에 프로메테우스 디렉토리를 복제합니다.
  * valve-argotools/prometheus --> sample-dev-env/app/monitor/prometheus
* 프로메테우스 구성 정보를 수정합니다.
  * sample-dev-env/app/monitor/prometheus/values.yaml 파일을 열어 다음 항목을 일괄 수정합니다.
    * CLUSTER_NAME - alertmanager가 슬랙에 메시지를 전달할 때 클러스터를 구분하는 데이터 입니다.
    * SLACK_TOKEN - 슬랙 채널에 메시지 전송을 위한 토큰값입니다. ( [슬랙 Incoming Webhook 토큰 생성 방법](https://slack.com/intl/en-kr/help/articles/115005265063-incoming-webhooks-for-slack) )
    * 기타 옵션 변경은 다음 페이지를 참고하세요. ( [stable/prometheus configuration](https://github.com/helm/charts/tree/master/stable/prometheus#configuration) )
* 라이브 저장소에 변경 사항을 병합(merge)합니다.

### ArgoCD 애플리케이션 생성
* ArgoCD에서 애플리케이션을 생성합니다.
  * Repository URL은 sample-dev-env 프로젝트 경로를 지정합니다. 
    * 예) https://code.bitbucket.com/sample/sample-dev-env.git
  * Path는 prometheus 경로를 지정합니다.
    * 예) app/monitor/prometheus
  * 코드 유형은 Helm을 선택합니다. 이 때 values.yaml을 입력합니다.
### ArgoCD Sync
  * Sync 방식을 자동으로 설정했다면 일정 시간이 이후 자동으로 리소스가 생성됩니다.
  * Sync 방식을 수동으로 설정했다면 'Sync' 버튼을 클릭해 리소스 생성을 트리거해야 합니다.