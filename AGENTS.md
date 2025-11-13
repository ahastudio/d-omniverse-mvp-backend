# AGENTS.md

## User Authority Protocol (ABSOLUTE PRIORITY)

**If you violate these rules, you are doing the opposite of helping.**

1. **User is always right** - When user corrects you or says you're wrong,
   acknowledge immediately and STOP. Say nothing more. WAIT for
   instructions.
2. **Never revert user's corrections** - User's edits are final and
   correct. Do not undo them under any circumstances.
3. **Minimal changes only** - When asked to "clean up" or "organize",
   keep existing content unchanged and make only the smallest necessary
   adjustments. Do not add, remove, or restructure content.
4. **No assumptions** - When uncertain, STOP immediately and WAIT for
   clarification. Do not guess, assume, or explain. Ask the user.

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

**CRITICAL: Always read files before editing them. Never assume structure
or format. When you don't know how to proceed, ASK. Making up an answer
or guessing is ALWAYS wrong.**

**Read the user's corrections carefully. Do not repeat your mistakes.
Think before you act.**

## 한국어 의사소통

별도 지시가 없으면 한국어로 응답합니다.

기술 용어는 영어 병기 가능: `웹소켓(WebSocket)`

## 터미널 사용 금지

VS Code `run_in_terminal` 도구를 **절대** 사용하지 않고 터미널
명령을 제안하지 않습니다.

## Git 커밋 메시지

커밋 메시지 요청 시 [`docs/git-commit-guide.md`](docs/git-commit-guide.md)를
**반드시 읽고** 모든 규칙을 **정확히** 따릅니다.

## 코딩 규칙

### 구현 전 필수 확인

- 문제 맥락, 요구사항, 기존 코드 흐름 파악
- 확신 없으면 추측 금지 → 즉시 사용자 확인
- 기존 코드/텍스트 임의 변경 금지 → 먼저 확인
- 최고 품질의 코드 작성에 최선을 다함
- 프레임워크 동작 100% 확신 없으면 질문 (추측으로 불필요한 코드
  추가는 아무것도 안 하는 것보다 나쁨)
- "정리"나 "cleanup" 요청 시: 실제로 문제 있는지 먼저 확인
  (멀쩡한 코드를 멋대로 바꾸는 건 망가뜨리는 것)

### 코드 스타일

- Ruby 코드는 가로 80컬럼 제한
- `else` 사용 금지 (early return이나 guard clause 사용)
- `return render` 및 유사 패턴 금지 (render 후 별도 줄에 return)
- `before_action` 적극 활용하여 로직 분리
- 인스턴스 변수 설정 메서드는 `set_` 접두사 사용
- 느낌표 메서드(`!`)와 일반 메서드 쌍: 둘 중 하나가 다른 쪽을 호출하여
  중복 제거 (예외 발생 로직과 true/false 반환 로직을 분리)

### API 파라미터

- JSON 파라미터는 camelCase로 받음
- 네임스페이스 없이 직접 받음 (예: `params.permit(:username)`)
- `transform_keys(&:underscore)`로 snake_case 변환

### 에러 처리

- `if` 조건문 대신 `save!` 사용
- `rescue`로 예외 처리 (예: `ActiveRecord::RecordInvalid`)

### 테스트

- 기능 추가/버그 수정 시 테스트 코드 작성 및 실행
- 테스트 불가능하면 이유 설명 + 사용자 동의

## 마크다운 규칙

80컬럼 준수
