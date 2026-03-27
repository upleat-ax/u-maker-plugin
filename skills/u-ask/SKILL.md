---
name: u-ask
description: "u-maker 프로젝트에 대한 질문, 제안, 의견을 자유롭게 물어볼 수 있는 Q&A 커맨드. SSoT 문서, 스킬 구성, 네이밍, 아키텍처 등에 대해 맥락을 이해한 답변을 제공한다."
triggers:
  - "/u-ask"
  - "u-maker 질문"
  - "u-maker에 대해"
---

# u-ask -- Context-Aware Q&A

`/u-ask {질문}` 명령으로 u-maker 프로젝트에 대한 질문, 제안, 의견을 자유롭게 물어본다.

> `/u-discuss`는 구조화된 다자간 토론 세션이고, `/u-ask`는 가볍게 질문/제안하는 1:1 대화이다.

---

## 사용 예시

```
/u-ask u-dev를 u-dev로 하는건 어때?
/u-ask ERD에서 soft delete를 기본으로 하는 이유가 뭐야?
/u-ask /u-plan과 /u-design의 경계가 뭐야?
/u-ask screens.json 구조를 바꾸고 싶은데 영향 범위가 어떻게 돼?
/u-ask 모노레포에서 common 문서는 어떻게 상속돼?
```

---

## Execution Flow

### Step 1: Parse Question

1. `/u-ask` 이후의 텍스트를 질문으로 인식
2. 질문 의도 분류:

| 의도 | 키워드 패턴 | 예시 |
|------|-----------|------|
| **제안/변경** | ~하는건 어때, ~로 바꾸면, ~로 하자, rename, change | "u-dev를 u-dev로 하는건 어때?" |
| **이유/설명** | 왜, 이유, 뭐야, 어떻게, explain, why | "soft delete를 기본으로 하는 이유가 뭐야?" |
| **영향 분석** | 영향, 범위, 바꾸면, impact, affect | "screens.json 구조를 바꾸면 영향이?" |
| **비교** | 차이, 경계, vs, 비교, difference | "/u-plan과 /u-design의 경계가 뭐야?" |
| **방법/절차** | 어떻게, 방법, how to, 절차 | "모노레포에서 앱을 추가하려면?" |

### Step 2: Gather Context

질문 대상에 따라 관련 파일을 자동으로 읽어 맥락을 확보한다.

| 질문 대상 | 읽는 파일 |
|----------|----------|
| 특정 스킬 (`/u-dev`, `/u-plan` 등) | `skills/{skill}/SKILL.md` |
| 특정 문서 (ERD, SRS 등) | `docs/{scope}/02-design/{doc}.md` + `.json` |
| 프로젝트 설정 | `u-maker.config.json`, `app.config.json` |
| 문서 구조 | `_index.json`, `_links.json` |
| 에이전트 | `agents/{agent}.md` |
| 전체 구조 | `skills/u-maker/SKILL.md` (Command Table) |

### Step 3: Respond

의도별 응답 형식:

#### 제안/변경 의도

제안에 대해 **장점/단점/영향 범위**를 분석하여 응답한다.

```markdown
## 제안: {요약}

### 분석
- **현재:** {현재 상태}
- **제안:** {변경 내용}

### 장점
- {장점 1}
- {장점 2}

### 단점/리스크
- {단점 1}

### 영향 범위
- {영향받는 파일/스킬 목록}

### 결론
{추천 의견}

---
> 이 변경을 진행하시겠습니까? "응" 또는 구체적인 지시를 주세요.
```

#### 이유/설명 의도

관련 스킬/문서를 참조하여 맥락 있는 설명을 제공한다.

#### 영향 분석 의도

`_links.json` 의존성 그래프를 탐색하여 cascade 영향 범위를 보여준다.

#### 비교 의도

두 대상을 테이블로 비교한다.

### Step 4: Action Follow-up (선택적)

제안/변경 의도에서 사용자가 동의하면:
1. 해당 변경을 직접 수행하거나
2. 적절한 `/u-*` 커맨드를 안내한다

---

## Safety Rules

1. `/u-ask`는 조회/분석만 수행하며, 사용자 동의 없이 파일을 수정하지 않음
2. 제안에 대한 결론은 항상 장단점을 균형 있게 제시
3. 영향 분석 시 `_links.json` 의존성을 반드시 확인
4. 불확실한 답변은 "확인이 필요합니다"로 명시하고, 확인 방법 안내
5. 질문이 u-maker 범위 밖이면 해당 사실을 안내
