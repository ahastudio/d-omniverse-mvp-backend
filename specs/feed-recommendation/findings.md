# Findings

## Requirements

- [x] 로그인 사용자: 관계 점수 기반 피드 정렬
- [x] 본인 게시물 최상단 노출
- [x] 동일 점수일 때 최신순 정렬
- [x] 비로그인 사용자: 최신순 유지
- [x] 기존 `type=video` 필터와 호환

## Research Findings

### 기존 코드 분석

- `PostsController#index`: 현재 `order(id: :desc)` 최신순 정렬만 수행
- `UserRelationship`: `user_id` → `target_user_id` 방향의 단방향 점수 저장
- `Post.visible` scope: `deleted_at IS NULL` 조건

### Twitter(X) 추천 알고리즘 참고

- **Real Graph**: 두 사용자 간 engagement 가능성을 예측하는 모델
  - 우리의 `UserRelationship.score`와 유사한 개념
  - 점수가 높을수록 해당 사용자의 트윗이 더 많이 포함됨

- **In-Network / Out-Network 비율**
  - Twitter는 팔로우한 사람(50%) vs 안 한 사람(50%) 균형 유지
  - 우리는 연결된 사람 우선, 나머지는 최신순으로 단순화

- **Engagement Weights**
  - Twitter: 답글 > 좋아요(30x) > 리트윗(20x)
  - 우리: `profile_view: 1, reaction: 2, post_view: 1`

- **Author Diversity**
  - 같은 작성자의 연속 게시물 방지로 피드 다양성 확보
  - 추후 고려 가능

## Technical Decisions

- **로그인 사용자만 추천 정렬**: 비로그인은 관계 데이터 없음
- **본인 게시물 인터리빙 전략** (최종 결정):
  - 본인 최신 글 1개만 최상단 고정 (`is_top_own = 1`)
  - 나머지 본인 글은 중간 점수(10) 부여
  - 이유: 본인 글이 많을 때 관계 있는 사람 글이 묻히는 문제 해결
- **LEFT JOIN 사용**: N+1 쿼리 방지
- **COALESCE(score, 0)**: 관계 없는 사용자 처리
- **시간 가중치(time decay) 미적용**: 현재는 순수 관계 점수만 사용
  - 동일 점수일 때만 최신순 적용
  - 관계 점수 54인 어제 글 > 관계 점수 5인 오늘 글
  - 향후 시간 decay 추가 고려 가능 (예: `score - days_old`)

### 향후 개선 가능성

#### 1. 친구의 친구 (2-hop Relationship)

**목표**: 직접 관계 없어도 친구의 친구면 가중치 부여

**개념**:

```text
나 → A (관계 점수 50)
A → B (관계 점수 30)
따라서: 나 → B = 간접 관계 (2-hop)
```

**점수 계산**:

```text
직접 관계: UserRelationship.score (예: 50)
간접 관계: MAX(친구들의 점수) * 감쇠율 (예: 30 * 0.3 = 9)
최종 점수: MAX(직접, 간접)
```

**구현 방식**:

```sql
-- 간접 관계 점수 (친구의 친구)
SELECT
  ur2.target_user_id AS indirect_target,
  MAX(ur1.score * ur2.score / 100) AS indirect_score
FROM user_relationships ur1
JOIN user_relationships ur2
  ON ur1.target_user_id = ur2.user_id
WHERE ur1.user_id = :current_user_id
  AND ur2.target_user_id != :current_user_id
GROUP BY ur2.target_user_id
```

**감쇠율 고려사항**:

- 너무 높으면: 간접 관계가 직접 관계를 압도
- 너무 낮으면: 간접 관계 효과 미미
- 권장: 0.2 ~ 0.5 사이 (테스트 후 조정)

#### 2. 시간 가중치 (Time Decay)

**목표**: 오래된 글은 점수를 낮춤

**공식 예시**:

```text
final_score = relationship_score - (days_old * decay_rate)
decay_rate: 0.1 ~ 0.5 (테스트 후 조정)
```

### 알고리즘 상세

#### 점수 부여 규칙

```text
is_top_own (최우선):
  - 본인 최신 게시물 1개: 1
  - 나머지: 0

base_score:
  - 본인 최신 제외한 나머지 본인 글: 10
  - 관계 있는 사용자: UserRelationship.score (예: 5, 19, 54 등)
  - 관계 없는 사용자: 0

diversity_score (작성자 다양성 적용):
  - base_score / author_post_rank
  - author_post_rank: 해당 작성자의 게시물 중 몇 번째인지 (1부터 시작)
  - 예시:
    * 본인 2번째 글: 10 / 2 = 5.0
    * dancer 1번째 글: 5 / 1 = 5.0
    * dancer 2번째 글: 5 / 2 = 2.5
    * kitty 1번째 글: 54 / 1 = 54.0
    * kitty 2번째 글: 54 / 2 = 27.0
```

#### 정렬 순서

```sql
ORDER BY
  is_top_own DESC,           -- 1단계: 본인 최신 글 최상단
  diversity_score DESC,      -- 2단계: 다양성 점수 높은 순
  posts.id DESC              -- 3단계: 동일 점수면 최신순
```

#### 실제 피드 예시 (admin 사용자)

```text
1. [본인 최신] admin (is_top_own=1, diversity=10)
2. [관계] kitty 1번째 (diversity=54/1=54)
3. [관계] kitty 2번째 (diversity=54/2=27)
4. [관계] omni 1번째 (diversity=19/1=19)
5. [관계] kitty 3번째 (diversity=54/3=18)
6. [본인] admin 2번째 (diversity=10/2=5)
7. [관계] dancer 1번째 (diversity=5/1=5)
8. [관계] omni 2번째 (diversity=19/2=9.5)
9. [본인] admin 3번째 (diversity=10/3=3.33)
10. [관계] creator 1번째 (diversity=3/1=3)
...

→ 같은 작성자가 3번 이상 연속으로 나오지 않음 ✅
```

#### SQL 구현

```sql
-- 1. 본인 최신 게시물 ID 조회 (서브쿼리)
SELECT id FROM posts
WHERE user_id = :current_user_id
  AND deleted_at IS NULL
ORDER BY id DESC
LIMIT 1

-- 2. 작성자별 순번 부여 (윈도우 함수)
SELECT posts.*,
       ROW_NUMBER() OVER (
         PARTITION BY posts.user_id
         ORDER BY posts.id DESC
       ) AS author_post_rank
FROM posts
WHERE posts.deleted_at IS NULL

-- 3. 메인 쿼리
SELECT posts.*,
       CASE WHEN posts.id = :latest_own_post_id THEN 1 ELSE 0 END AS is_top_own,
       CASE
         WHEN posts.user_id = :current_user_id THEN 10
         ELSE COALESCE(user_relationships.score, 0)
       END AS base_score,
       CASE
         WHEN posts.user_id = :current_user_id THEN 10.0 / author_post_rank
         ELSE COALESCE(user_relationships.score, 0) / author_post_rank
       END AS diversity_score
FROM (subquery_with_author_post_rank) AS posts
LEFT JOIN user_relationships
  ON user_relationships.user_id = :current_user_id
  AND user_relationships.target_user_id = posts.user_id
ORDER BY is_top_own DESC,
         diversity_score DESC,
         posts.id DESC
```

#### 점수 조정 히스토리

1. **초기 구현**: 본인 글 전체 최상단 (`is_self = 1/0`)
   - 문제: 본인 글 8개 → 관계 글들이 9번째 이후로 밀림

2. **1차 수정**: 나머지 본인 글 30점
   - 문제: 여전히 본인 글이 뭉쳐서 관계 글 시각성 낮음

3. **2차 수정**: 나머지 본인 글 10점
   - 결과: 높은 관계(54, 19) → 본인 나머지(10) → 낮은 관계(5, 3, 2)
   - 문제: 같은 작성자가 연속으로 나와서 다양성 부족

4. **최종 구현**: diversity_score = base_score / author_post_rank
   - 결과: 각 작성자의 첫 번째 글 우선 → 두 번째 글 → 세 번째 글 순서로 자연스럽게 섞임
   - 효과: 작성자 다양성 확보 + 관계 점수 반영 ✅

## Issues Encountered

### 1. UserRelationships 테스트 실패

**문제**: fixture에 `admin_to_creator` 관계 추가 후 기존 테스트 실패

**원인**: 테스트가 admin의 관계가 1개라고 가정

**해결**: 테스트에서 관계 개수를 1에서 2로 수정

### 2. 프론트엔드에서 인증 토큰 미전달

**문제**: 피드 추천이 작동하지 않고 항상 최신순으로 표시됨

**원인**: `fetchPosts.ts`, `fetchVideoPosts.ts`에서 `Authorization` 헤더 누락

**해결**: `getAccessToken()`으로 토큰을 가져와서 헤더에 추가

```typescript
// 수정 전
headers: {
  'Content-Type': 'application/json',
}

// 수정 후
const accessToken = await getAccessToken();
headers: {
  'Content-Type': 'application/json',
  Authorization: `Bearer ${accessToken}`,
}
```

### 3. 본인 게시물이 너무 많아서 관계 글이 안 보임

**문제**: 본인 게시물이 8개인 경우, 관계 점수 높은 글들이 9번째 이후에 나옴

**원인**: 초기 구현에서 본인 글 전체를 최상단에 배치

**해결**:

- 본인 최신 글 1개만 최상단 고정 (`is_top_own`)
- 나머지 본인 글은 중간 점수(10) 부여하여 관계 글들 사이에 인터리빙
- 결과: 본인 최신글 → 높은 관계글 → 본인 글들 → 낮은 관계글 순

## Resources

- [Twitter/X Recommendation Algorithm (GitHub)](https://github.com/twitter/the-algorithm-ml)
- [Twitter's Recommendation Algorithm](https://blog.twitter.com/engineering/en_us/topics/open-source/2023/twitter-recommendation-algorithm)
- [Twitter 추천 알고리즘 분석 (한글)](https://jiho-kang.tistory.com/10)
- `app/controllers/posts_controller.rb` - 현재 피드 구현
- `app/models/user_relationship.rb` - 관계 점수 모델

## Learnings

### TDD 프로세스

1. **Red**: 실패하는 테스트 먼저 작성 (fixture 추가 포함)
2. **Green**: 컨트롤러에서 SQL 직접 작성하여 테스트 통과
3. **Refactor**: 로직을 Post 모델 scope로 추출하여 관심사 분리

### SQL 작성 팁

- `CASE WHEN`으로 가상 컬럼 생성 (`is_self`)
- `COALESCE(score, 0)`로 NULL 처리
- `LEFT JOIN`으로 관계 없는 사용자도 포함
- `ORDER BY` 다중 조건으로 우선순위 정렬

### Rails 패턴

- scope에서 복잡한 SQL도 깔끔하게 정의 가능
- `includes(:user)` N+1 쿼리 방지
- `current_user` 존재 여부로 로그인/비로그인 분기

### 테스트 작성 팁

- fixture는 최소한으로 유지하되 필요한 만큼 추가
- 다른 테스트에 영향 줄 수 있음을 인지
- 정렬 검증 시 `index` 비교가 명확함

### 테스트 전략 (체계적 검증)

#### 1. 기본 정렬 테스트 (`test_GET_/posts_-_authenticated_user_-_recommended_order`)

주요 검증 항목:

- 본인 최신 글이 0번 인덱스(최상단)인지
- **작성자 다양성: 같은 작성자 3번 이상 연속 금지**
- 높은 관계 점수(dancer 5점) < 낮은 관계 점수(creator 3점)

#### 2. 알고리즘 검증 테스트 (`test_GET_/posts_-_feed_algorithm_verification`)

핵심 알고리즘 검증:

- 본인 최신 글이 최상단
- **작성자 다양성: 같은 작성자 3번 이상 연속 금지**

작성자 다양성은 diversity_score = base_score / author_post_rank 공식으로 자동 달성됨.

### 코드 스타일

- **else 없이 더 좋은 구조**: if-else 대신 guard clause + 값 반환 메서드로 분리
  - 나쁜 예: `if current_user ... else ... end`
  - 좋은 예: `return ... if current_user` + 기본값 반환
  - 인스턴스 변수 설정(`set_*`)과 값 반환(`*_for_*`) 메서드를 분리하면 더 명확

### 피드 인터리빙 전략

- **본인 글 최신 1개 최상단 고정**: 서브쿼리로 최신 본인 글 ID 찾아서 `is_top_own` 필드 생성
- **나머지 본인 글에 적절한 점수 부여**: 10점으로 설정하여 중간 관계 글들 사이에 자연스럽게 배치
- **점수 기반 정렬**: `ORDER BY is_top_own DESC, relationship_score DESC, id DESC`
- **결과**: 본인 최신 → 높은 관계(54) → 중간 관계(19) → 본인 나머지(10) → 낮은 관계(5,3,2) 순

### 프론트엔드 API 호출

- **인증이 필요한 API는 모두 토큰 전달 필수**: GET 요청도 예외 아님
- **일관성 체크**: `createPost`, `deletePost`에 토큰 있으면 `fetchPosts`에도 있어야 함
- **추천 로직이 안 먹으면**: 먼저 `current_user`가 nil인지 확인

## Test Data Generation

### 봇 계정 프로필 정비

글 없는 계정들을 봇으로 활용하여 테스트 데이터 생성:

```ruby
# 프로필 업데이트 (닉네임 + 아바타)
profiles = {
  "username" => {
    nickname: "닉네임",
    avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=xxx"
  },
}

profiles.each do |username, attrs|
  User.find_by(username: username)&.update(attrs)
end
```

**아바타 생성**: [DiceBear](https://www.dicebear.com/) API 활용

- 사람 스타일: `avataaars`
- 캐릭터/봇 스타일: `bottts`

### 랜덤 게시물 생성

```ruby
require "ulid"

contents = ["내용1", "내용2", ...]
now = Time.current

User.find_by(username: "bot_username").tap do |user|
  # 최근 30일 내 랜덤 시간
  days_ago = rand(0..30)
  hours_ago = rand(0..23)
  created_at = now - days_ago.days - hours_ago.hours

  # ULID는 created_at 기준으로 생성 (정렬 순서 보장)
  Post.create(
    id: ULID.generate(created_at),
    user: user,
    content: contents.sample,
    created_at: created_at,
    updated_at: created_at
  )
end
```

**주의**: `ULID.generate(created_at)`으로 시간 기반 ID 생성 필수

### 현재 테스트 데이터 현황 (135개 게시물)

**캐릭터 페르소나**:

| username | nickname | 페르소나 |
| -------- | -------- | -------- |
| tester | Tester | QA 엔지니어, 버그 사냥꾼 |
| minjun | 박민준 | 대학생, 컴공 3학년, 알고리즘 스터디 |
| pikachu | 피카츄 | 포켓몬, 전기 타입, 사토시 파트너 |
| yuna | 최유나 | 프리랜서 일러스트레이터, 고양이 집사 |
| spiderman | 스파이더맨 | 뉴욕 히어로, 친절한 이웃 |
| haneul | 김하늘 | 요가 강사, 비건, 아침형 인간 |
| test | 테디베어 | 인형, 포근함 담당 |
| test1 | 정우진 | 스타트업 개발자, 야근 전문가 |
| harry | 해리포터 | 호그와트 졸업생, 마법사 |
| jiwon | 송지원 | 마케터, SNS 덕후, 트렌드 수집가 |
| aabbcc11 | 이서연 | 취준생, INFP, 독서 모임 운영 |
| omniverse | 아이언맨 | 천재 발명가, 어벤져스 멤버 |
| dohyun | 이도현 | 음악 프로듀서, 비트 메이커 |
| a1234 | 엘사 | 아렌델 여왕, 얼음 마법 |
| a123 | 강다인 | 대학원생, AI 연구 |
| omni | 옴니버스 | 플랫폼 운영자, 댄스 커뮤니티 |
| kitty | Hello Kitty | 산리오 캐릭터 덕후 |
| honggildong | 홍길동 | 의적, 활빈당 당주 |
| domniverse | 디옴니버스 | 댄스 크루 리더, 스트릿 댄서 |
| kimchulsoo | 김철수 | 직장인, 야구 덕후, 등산러 |
| kkim | 김예헌 | 고등학생, 입시 준비 |
| user | 사용자11 | 신규 가입자 |

**게시물 특징**:

- 각 캐릭터의 페르소나에 맞는 고유한 내용
- 가입일 이후~현재까지 랜덤 시간 분포
- 긴 내용의 게시물 포함 (일상, 고민, 성과 등)
- 중복 내용 없음
