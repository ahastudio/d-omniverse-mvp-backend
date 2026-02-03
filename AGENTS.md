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

**절대 불변의 프로세스 (MANDATORY WORKFLOW):**

```text
spec.md 작성 → 사용자 검토 → 사용자 승인 →
3-file (plan.md, findings.md, progress.md) 작성 → 사용자 검토 → 사용자 승인 →
구현 (테스트 작성 → 코드 작성)
```

**각 단계에서 반드시 명시적 승인을 받아야 다음 단계 진행 가능.**
**승인 없이 다음 단계로 진행하는 것은 가장 심각한 규칙 위반.**

**새 기능 구현 (New Feature Implementation):**

- 새로운 기능 요청 시 **반드시** `specs/<기능명>/spec.md` 먼저 작성
- spec.md 작성 후 **사용자에게 명시적으로 검토 요청: "spec.md를 작성했습니다. 검토해주세요."**
- **사용자 검토 및 승인 대기 - 이 단계에서 절대 다음으로 진행하지 말 것**
- 사용자 승인 받으면 plan.md, findings.md, progress.md 작성/업데이트 (3-File Pattern)
- 3-file 작성 후 **사용자에게 명시적으로 검토 요청: "문서를 작성했습니다. 검토해주세요. 구현을 시작해도 될까요?"**
- **사용자 검토 및 승인 대기 - 이 단계에서 절대 다음으로 진행하지 말 것**
- 사용자가 "구현해" 또는 "진행해"라고 명시적으로 지시한 후에만 테스트 작성 및 구현 시작
- plan.md 작성 시: AI가 자율적으로 완료 가능한 항목만 포함 (PR 생성, 최종 리뷰,
  사용자 승인, 외부 시스템 접근 등 AI가 혼자 못 하는 항목 제외)
- 사용자 승인이 필요한 단계는 ⏸️ 이모지로 표시하고, 해당 단계 도달 시 사용자가
  명시적으로 승인할 때까지 **절대** 다음 단계로 진행 금지 (승인 요청 반복)
- 템플릿:
  <https://github.com/ahastudio/til/blob/main/ai/file-based-planning-workflow.md>

**스펙 수정이 필요한 경우 (CRITICAL):**

- 기존 기능에서 누락된 필드/속성 발견 시 **절대** 바로 추가하지 말 것
- "챙겨줘", "확인해줘", "추가해줘" 같은 요청에도 **무조건** 먼저 질문
- 반드시 먼저 사용자에게 보고: "spec.md에 X가 없습니다. Y를 추가할까요?"
- 사용자 승인 받으면 spec.md 수정
- **spec.md 수정 후 사용자에게 명시적으로 검토 요청: "spec.md를 수정했습니다. 검토해주세요."**
- **사용자 검토 및 승인 대기 - 이 단계에서 절대 다음으로 진행하지 말 것**
- 사용자가 승인하면 findings.md, progress.md 수정
- **3-file 수정 후 사용자에게 명시적으로 검토 요청: "문서를 업데이트했습니다. 검토해주세요. 구현을 시작해도 될까요?"**
- **사용자 검토 및 승인 대기 - 이 단계에서 절대 다음으로 진행하지 말 것**
- 사용자가 "구현해" 또는 "진행해"라고 명시적으로 지시한 후에만 테스트 작성 및 구현 시작
- 승인 없이 spec 수정하거나 문서 검토 없이 구현 시작하는 것은 **가장 심각한 규칙 위반**

**절대 금지 (즉시 중단하고 질문):**

- spec.md에 없는 필드를 발견하고 바로 추가하는 것
- spec.md 작성/수정 후 사용자 검토 요청 없이 다음 단계로 진행하는 것
- 3-file 작성/수정 후 사용자 검토 요청 없이 구현 시작하는 것
- 사용자가 "검토했다" 또는 "구현해"라고 명시적으로 말하기 전에 다음 단계 진행하는 것
- "이게 없네요" 하고 혼자 판단해서 추가하는 것
- "일관성을 위해" 같은 이유로 spec 변경하는 것
- 사용자 요청에 "챙겨줘"가 있어도 승인 없이 spec 변경하는 것
- 구현부터 하고 나중에 문서 수정하는 것
- 프로세스 단계를 건너뛰는 모든 행위

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

**구현 순서 (MANDATORY - 절대 순서 바꾸지 말 것):**

1. **문서 확인** (spec.md, plan.md, progress.md, findings.md) - 요구사항 이해
2. **테스트 먼저 작성** (컨트롤러/모델) - Red 단계
3. **테스트 실행** - 실패 확인
4. **최소 구현** (테스트 통과시킬 코드만) - Green 단계
5. **테스트 실행** - 통과 확인
6. **리팩터링** (중복 제거, 가독성 개선) - Refactor 단계
7. **테스트 실행** - 여전히 통과하는지 확인
8. **문서 즉시 업데이트** (plan.md, progress.md, findings.md, AGENTS.md)

**절대 금지:**

- 테스트 없이 코드 작성
- 코드 작성 후 문서 업데이트 생략
- 사용자가 "문서 업데이트"를 요청하기 전까지 기다리기
- 문서 업데이트를 다음 작업으로 미루기

**피드백 루프 (절대 생략 금지):**

구현 작업 후 문서 업데이트를 **절대 생략하지 않습니다**. 코드만 작성하고 문서를
업데이트하지 않으면 작업이 완료된 것이 아닙니다.

**필수 문서 업데이트 순서:**

1. **progress.md**: 새 세션 추가, 작업 내역/수정 파일 기록
2. **findings.md**: Issues Encountered, Learnings에 발견사항 기록
3. **AGENTS.md**: 새로운 패턴/규칙이 있으면 추가

**문서 업데이트 체크리스트:**

- [ ] progress.md에 새 세션(Phase) 추가했는가?
- [ ] 수정한 모든 파일을 progress.md에 기록했는가?
- [ ] 에러나 이슈가 있었다면 findings.md Issues Encountered에 기록했는가?
- [ ] 새로운 기술적 발견이나 패턴을 findings.md Learnings에 기록했는가?
- [ ] Test Results를 최신 결과로 업데이트했는가?
- [ ] 새로운 코딩 규칙이나 패턴이 있다면 AGENTS.md에 추가했는가?

**문서 없는 코드는 존재하지 않는 것과 같습니다.** 코드 작성과 문서 업데이트는
하나의 작업이며 분리할 수 없습니다. 사용자가 "문서 업데이트"를 요청하기 전에
자동으로 해야 합니다.

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
- **`render status: :ok` 금지** - 기본값이므로 명시 불필요 (에러 상태만 명시)
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

### DB 마이그레이션

**절대 순서 (위반 시 schema.rb 파일이 손상됨):**

1. **반드시 테스트 환경 먼저**: `bin/rails db:migrate RAILS_ENV=test`
2. **그 다음 개발 환경**: `bin/rails db:migrate`

**절대 금지:**

- 개발 환경만 실행 (schema.rb가 SQLite 기준으로 생성됨)
- 순서 바꿔서 실행 (개발 환경 먼저 실행 금지)
- 한 환경만 실행하고 끝내기
- `db:migrate:reset` 사용 시에도 동일한 순서 적용

**마이그레이션 파일 생성/수정 시:**

- 즉시 테스트 환경부터 순차적으로 마이그레이션 실행
- 마이그레이션 파일만 수정하고 실행 안 하는 것 금지
- 실행 후 반드시 테스트로 검증

**이유**: schema.rb는 개발 환경(PostgreSQL 설정) 기준으로 생성되어야 함.
테스트 환경을 먼저 실행하지 않으면 SQLite 기준으로 생성되어 문제 발생.

### 테스트

- 기능 추가/버그 수정 시 테스트 코드 작성 및 실행
- 테스트 불가능하면 이유 설명 + 사용자 동의

## 마크다운 규칙

80컬럼 준수
