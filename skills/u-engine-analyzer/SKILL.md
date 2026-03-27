---
name: engine-analyzer
description: |
  _input/ 원시 자료(RFP, 회의록, AS-IS 문서)를 파싱하여
  청크 기반 분석 후 _classified/ 카테고리로 분류하는 분석 엔진.
version: 2.0.0
user-invocable: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
imports: []
---

# Engine: Analyzer

> 원시 입력 자료를 분석하여 구조화된 분류 데이터로 변환한다.

## 역할

- `_input/` 디렉토리의 원시 자료 파싱 (RFP, 회의록, AS-IS 문서 등)
- 컨텍스트 윈도우 한계를 고려한 청크 기반 분석
- 10개 카테고리로 데이터 분류 및 태깅
- 증분 분석: 신규/변경 파일만 처리
- 분류 결과 인덱스 및 요약 갱신

## Input / Output

| 구분 | 내용 |
|------|------|
| **Input** | `.u-maker/docs/{app}/_input/` 하위 원시 파일들 |
| **Output** | `.u-maker/docs/{app}/_classified/` 카테고리별 JSON + _index.json + _summary.json |

## 분류 카테고리

| 카테고리 | 설명 | 예시 |
|----------|------|------|
| `requirements` | 기능/비기능 요구사항 | "사용자는 로그인할 수 있어야 한다" |
| `pain-points` | 현행 시스템 문제점 | "검색 속도가 3초 이상 걸린다" |
| `domain-terms` | 도메인 용어 정의 | "SKU = 재고관리단위" |
| `stakeholders` | 이해관계자 정보 | "운영팀장 김OO, 승인 권한" |
| `workflows` | 업무 프로세스 흐름 | "주문접수 → 재고확인 → 출고" |
| `screens` | 화면/UI 관련 언급 | "대시보드에 실시간 차트 필요" |
| `data-models` | 데이터 구조 관련 | "주문 테이블에 상태 필드 추가" |
| `constraints` | 제약 조건 | "AWS 인프라만 사용 가능" |
| `decisions` | 기결정 사항 | "React + Next.js로 확정" |
| `questions` | 미확인/추가 질의 필요 | "결제 PG사 선정 여부?" |

## 실행 절차

### Step 1. 입력 파일 스캔

1. `_input/` 디렉토리의 모든 파일 목록 조회
2. `_manifest.json`과 비교하여 신규/변경 파일 식별
3. 변경 감지: 파일 해시(MD5) 비교

### Step 2. 청크 분할

대용량 파일 처리를 위한 청크 전략:
- 파일 크기 > 10KB 시 청크 분할
- 분할 기준: 섹션 헤더(`#`, `##`), 페이지 구분, 빈 줄 블록
- 각 청크에 출처 메타데이터 부착: `{ file, page, section, chunkIndex }`

### Step 3. 카테고리 분류

각 청크에 대해:
1. 내용 분석 → 해당 카테고리 판별 (복수 카테고리 가능)
2. 분류 항목 생성:
   ```json
   {
     "id": "CLF-0010",
     "category": "requirements",
     "content": "사용자는 소셜 로그인(Google, Kakao)으로 가입할 수 있어야 한다",
     "source": { "file": "RFP_v2.pdf", "page": 12, "section": "3.2 인증" },
     "status": "extracted",
     "tags": ["auth", "social-login"],
     "confidence": 0.95
   }
   ```
3. 카테고리별 JSON 파일에 항목 추가

### Step 4. 매니페스트 갱신

처리 완료 후 `_manifest.json` 갱신:
```json
{
  "lastProcessed": "2026-03-27T10:00:00Z",
  "files": {
    "RFP_v2.pdf": { "hash": "abc123", "processedAt": "...", "chunks": 15 }
  }
}
```

### Step 5. 인덱스 및 요약 갱신

- `_classified/_index.json`: 전체 분류 항목 레지스트리
- `_classified/_summary.json`: 카테고리별 항목 수, 주요 키워드, 미확인 질의 목록

## 오류 처리

| 상황 | 처리 |
|------|------|
| 지원하지 않는 파일 형식 | 경고 + skip (지원: .md, .txt, .pdf, .docx, .xlsx) |
| 청크 분할 실패 | 파일 전체를 단일 청크로 처리 |
| 분류 신뢰도 < 0.5 | `questions` 카테고리로 자동 분류 + 수동 검토 플래그 |
| _input/ 디렉토리 미존재 | 디렉토리 생성 + 안내 메시지 |
| 중복 항목 감지 | 기존 항목 유지 + 중복 후보 태깅 |

## 연동

- **호출원**: `u-skill-import`, `u-skill-srs`, `u-agent-ra` (분석 요청)
- **호출 대상**: 없음 (자체 파싱 + 분류)
- **후속 엔진**: engine-doc (분류 결과 기반 문서 생성), engine-designer (분류 데이터 참조)
