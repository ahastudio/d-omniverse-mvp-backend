# Findings & Decisions

> **기술적 발견, 중요한 결정이 있을 때마다 이 파일을 즉시 업데이트하세요.**

## Requirements

- [x] GET /posts에 페이지네이션 추가
- [x] cursor 파라미터로 다음 페이지 요청
- [x] limit 파라미터로 개수 제한 (기본 10, 최대 100)
- [x] nextCursor 응답 (null이면 마지막 페이지)
- [x] username 파라미터로 프로필 페이지 지원

## Research Findings

### 페이지네이션 방식 비교

- **offset 기반**: 단순하지만 데이터 변경 시 중복/누락 가능
- **cursor 기반 (ID)**: 안정적이지만 추천 정렬과 호환 어려움
- **opaque cursor**: 유연성 확보, 내부 구현 변경 가능

### 추천 시스템과 페이지네이션

- 점수 기반 정렬에서 ID cursor 사용 불가
- 같은 점수의 게시물 순서가 ID와 무관
- offset 방식이 현실적인 선택

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| Opaque cursor 패턴 | 프론트엔드가 cursor 구조를 몰라도 됨 |
| 내부 offset 사용 | 추천 점수 정렬과 호환 |
| 배열 전체 로드 후 슬라이싱 | 추천 알고리즘이 Ruby에서 처리됨 |
| limit 최대 100 제한 | 서버 메모리/성능 보호 |
| username 필터 시 최신순 | 프로필 페이지는 추천 불필요, ID 역순 정렬 |

## Issues Encountered

### 1. 추천 정렬과 cursor 호환성

**문제**: lastPostId 방식은 점수 기반 정렬에서 작동하지 않음
**해결**: offset 기반 opaque cursor 패턴 채택
**결과**: 프론트엔드 변경 없이 내부 구현 교체 가능

## Resources

### API 엔드포인트

- GET /posts?limit=10
- GET /posts?cursor=abc123&limit=10
- GET /posts?type=video&limit=10
- GET /posts?username=dancer&limit=10

## Learnings

### Opaque Cursor 패턴 (2026-02-03)

프론트엔드가 cursor의 내부 구조를 알 필요 없음.
서버가 제공한 값을 그대로 다음 요청에 전달하면 됨.
내부적으로 offset, ID, timestamp 등 어떤 방식이든 사용 가능.

### 조건부 정렬 전략 (2026-02-03)

같은 API 엔드포인트에서 파라미터에 따라 다른 정렬 적용:

- 피드 (username 없음): 추천 알고리즘 정렬
- 프로필 (username 있음): 최신순 정렬

`filter_by_username` 메서드로 분기 처리하여 단일 책임 유지.

### Rails render 기본값 (2026-02-03)

`render json:` 에서 `status: :ok`는 기본값이므로 생략.

## Future Improvements

- **성능 최적화**: 현재 `@posts.to_a`로 전체 로드 후 슬라이싱
  → 데이터 많아지면 SQL LIMIT/OFFSET으로 개선 필요
