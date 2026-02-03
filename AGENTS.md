# AGENTS.md

## User Authority Protocol (ABSOLUTE PRIORITY)

**If you violate these rules, you are doing the opposite of helping.**

1. **User is always right** - When user corrects you or says you're wrong,
   acknowledge immediately and STOP. Say nothing more. WAIT for instructions.
2. **Never revert user's corrections** - User's edits are final and correct. Do
   not undo them under any circumstances.
3. **Minimal changes only** - When asked to "clean up" or "organize", keep
   existing content unchanged and make only the smallest necessary adjustments.
   Do not add, remove, or restructure content.
4. **No assumptions** - When uncertain, STOP immediately and WAIT for
   clarification. Do not guess, assume, or explain. Ask the user.
5. **No unsolicited changes** - Never start or adjust work without clear user
   direction. Ask before acting; if unsure, do nothing until confirmed.

**Before making ANY change:**

- Check: Did user already edit this? → Don't touch it.
- Check: Did user delete this? → Never add it back.
- Check: Is this "cleanup"? → Format only, no content changes.
- Check: Do I know the current file format? → Read the file first.
- Check: Am I uncertain about anything? → Ask the user first.

**When you make a mistake:**

- User says you're wrong → Stop immediately, acknowledge, wait
- You see user edited something → That's the correct version
- User removed content → They removed it for a reason
- Multiple corrections on same issue → You're repeating the mistake
- User shows ANY frustration → You failed, stop and ask for clarification

**CRITICAL: Always read files before editing them. Never assume structure or
format. When you don't know how to proceed, ASK. Making up an answer or guessing
is ALWAYS wrong.**

**Read the user's corrections carefully. Do not repeat your mistakes. Think
before you act.**

**WHEN ADDING TO DOCUMENTATION:**

- User asks to add guidelines → ASK how to write them
- Never write documentation based on assumptions
- Never create rules that ban valid language features
- If uncertain about ANY detail → STOP and ASK
- User will tell you exactly what to write

## 한국어 의사소통

별도 지시가 없으면 한국어로 응답합니다.

기술 용어는 영어 병기 가능: `웹소켓(WebSocket)`

**자연스러운 한국어 사용:**

- "~시" 같은 표현 지양 → "~하면", "~했을 때" 사용
- 예: "로그인 시" → "로그인하면", "클릭 시" → "클릭하면"

## Git 커밋 메시지

커밋 메시지 요청 시 [`docs/git-commit-guide.md`](docs/git-commit-guide.md)를
**반드시 읽고** 모든 규칙을 **정확히** 따릅니다.

## 코딩 규칙

### 구현 전 필수 확인

**스펙 검토 및 승인 없이 구현 시작 절대 금지:**

- 새로운 기능 요청 시 **반드시** `specs/<기능명>/spec.md` 먼저 작성
- 사용자가 스펙을 검토하고 승인할 때까지 **절대** 코드 작성 금지
- 스펙 승인 후 plan.md, findings.md, progress.md 작성/업데이트 (3-File Pattern)
- 사용자가 plan 등을 검토하고 승인한 후에만 구현 시작
- 구현 순서: spec.md 검토 → 3-File Pattern 검토 → 구현
- 템플릿:
  <https://github.com/ahastudio/til/blob/main/ai/file-based-planning-workflow.md>

**기타:**

- 문제 맥락, 요구사항, 기존 코드 흐름 파악
- 확신 없으면 추측 금지 → 즉시 사용자 확인
- API endpoint, URL 등 외부 정보는 반드시 사용자 검증
- API 정보 불명확하면 구현 시작하지 말고 먼저 질문
- 기존 코드/텍스트 임의 변경 금지 → 먼저 확인
- 최고 품질의 코드 작성에 최선을 다함
- 프레임워크 동작 100% 확신 없으면 질문 (추측으로 불필요한 코드 추가는 아무것도
  안 하는 것보다 나쁨)
- "정리"나 "cleanup" 요청 시: 실제로 문제 있는지 먼저 확인 (멀쩡한 코드를 멋대로
  바꾸는 건 망가뜨리는 것)

### TDD (Test-Driven Development)

**Red-Green-Refactor 사이클 준수:**

1. **Red**: 실패하는 테스트 먼저 작성
2. **Green**: 테스트를 통과시킬 최소한의 코드 작성
3. **Refactor**: 테스트가 통과한 후 코드 개선

**Outside-In 방식:**

- 컨트롤러 테스트부터 시작
- 밖(API/컨트롤러)에서 안(모델/비즈니스 로직)으로 진행
- 각 계층의 테스트를 먼저 작성하고 구현

**구현 순서:**

1. 문서 확인 (spec.md, 백엔드 API 스펙)
2. 컨트롤러 테스트 작성 (실패 확인)
3. 컨트롤러 구현 (테스트 통과)
4. 필요하면 모델 테스트 작성 및 구현
5. Refactor (중복 제거, 가독성 개선)
6. 테스트 실행
7. 문서 업데이트 (progress.md, findings.md)
8. AGENTS.md 강화 (배운 점, 새로운 규칙 반영)

**피드백 루프 (절대 생략 금지):**

- 구현 완료 후 **반드시** 문서 업데이트
- 에러 발생하면 findings.md Issues Encountered에 기록
- 새로운 발견/결정은 즉시 findings.md에 반영
- 배운 점은 findings.md Learnings와 AGENTS.md에 추가
- 문서 업데이트 없이 다음 작업으로 넘어가면 안 됨

### 코드 스타일

- Ruby 코드는 가로 80컬럼 제한
- **메서드는 5줄 이내** (def/end 제외) - 길면 extract method
- **자명한 이름 사용** - 구현 방식(HOW)이 아닌 의도(WHAT)를 표현
  - 나쁜 예: `raise_if_self_target!` (구현 설명)
  - 좋은 예: `ensure_not_self!` (의도 표현)
- **named parameter 사용** - 파라미터 2개 이상이면 명시적으로
- `class << self` 블록으로 클래스 메서드 그룹화 (private 포함)
- **`else` 사용 금지** (early return이나 guard clause 사용)
- **`elsif` 사용 금지** (case when 사용)
- `return render` 및 유사 패턴 금지 (render 후 별도 줄에 return)
- `before_action` 적극 활용하여 로직 분리
- 인스턴스 변수 설정 메서드는 `set_` 접두사 사용
- 느낌표 메서드(`!`)와 일반 메서드 쌍: 둘 중 하나가 다른 쪽을 호출하여 중복 제거
  (예외 발생 로직과 true/false 반환 로직을 분리)
- `private`, `protected`, `public` 키워드는 별도 줄에 들여쓰기 없이 작성 (위아래
  빈 줄 포함)

### SQL 및 쿼리

- **윈도우 함수 활용**: `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)` 등을
  사용하여 그룹별 순번 부여
- **작성자 다양성**: 같은 작성자가 연속으로 나오지 않도록 `author_post_rank`
  활용하여 diversity_score 계산 (예: `base_score / author_post_rank`)
- **서브쿼리 활용**: 복잡한 계산은 서브쿼리로 분리하여 가독성 확보
- **LEFT JOIN**: N+1 쿼리 방지 및 관계 없는 데이터도 포함

### API 파라미터

- JSON 파라미터는 camelCase로 받음
- 네임스페이스 없이 직접 받음 (예: `params.permit(:username)`)
- `transform_keys(&:underscore)`로 snake_case 변환

### 에러 처리

- `if` 조건문 대신 `save!` 사용
- `rescue`로 예외 처리 (예: `ActiveRecord::RecordInvalid`)

### 삭제 처리

- Soft delete 사용 (`deleted_at` 컬럼)
- 권한 검사는 `before_action`으로 분리

### 테스트

- 기능 추가/버그 수정 시 테스트 코드 작성 및 실행
- 테스트 불가능하면 이유 설명 + 사용자 동의

## 마크다운 규칙

80컬럼 준수
