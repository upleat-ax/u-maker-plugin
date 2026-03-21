# 기여자별 작업 내역 (Contributors) — 상세

git 이력을 분석하여 누가 어떤 작업을 했는지 상세하게 표시한다.

## Data Collection

```bash
# 기여자별 커밋 수
git shortlog -sn --no-merges

# 기여자별 변경 통계
git log --format='%aN' --no-merges | sort -u | while read author; do
  echo "$author"
  git log --author="$author" --no-merges --shortstat
done

# 기여자별 주요 작업 영역 (디렉토리 기준)
git log --author="<name>" --no-merges --name-only --pretty=format: | sort | uniq -c | sort -rn | head -20
```

## 기여자 요약 테이블

| 기여자 | 커밋 수 | 비율 | 추가 라인 | 삭제 라인 | 주요 작업 영역 |
|--------|---------|------|-----------|-----------|--------------|
| Alice | 23 | 46% | +1,245 | -312 | src/app/, src/components/ |
| Bob | 18 | 36% | +890 | -156 | src/api/, prisma/ |
| Claude | 9 | 18% | +445 | -89 | docs/, tests/ |

## 기여자별 작업 상세

각 기여자마다 `.ft-card` 스타일의 카드로 표시:

```html
<div class="ft-grid">
  <div class="ft-card">
    <div class="ft-card-header">
      <h5>Alice</h5>
      <span class="badge badge-primary">23 commits (46%)</span>
    </div>
    <ul>
      <li><strong>feat</strong>: 회원가입 화면 구현, 대시보드 레이아웃 (12건)</li>
      <li><strong>fix</strong>: 로그인 토큰 만료 처리, 폼 유효성 검증 (6건)</li>
      <li><strong>refactor</strong>: API 클라이언트 모듈화 (3건)</li>
      <li><strong>주요 파일</strong>: src/app/auth/, src/components/dashboard/</li>
    </ul>
  </div>
</div>
```

- 커밋 메시지 prefix(feat/fix/refactor/docs/test/chore)별 갯수와 주요 내용 요약
- 주요 작업 파일/디렉토리 Top 5 표시
- `Co-Authored-By` 헤더가 있으면 공동 작업자로 함께 표시
