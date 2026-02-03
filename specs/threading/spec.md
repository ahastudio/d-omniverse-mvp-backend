# 스레드 기능 사양서 (Threading Feature Specification)

## 개요

D-Omniverse 소셜 미디어에 스레드(Threading) 기능을 추가한다. 현재는 각
글(Post)이 독립적으로 존재하지만, 이 기능을 통해 글들이 `parent_id`로 서로
연결되어 대화 형태의 스레드를 형성할 수 있다.

## 목표

1. 모든 글은 다른 글의 자식이 될 수 있다 (스레드 연결)
2. 특정 글의 답글 목록을 조회할 수 있다
3. 특정 글의 상위 스레드(조상 목록)를 조회할 수 있다

## 용어 정의

| 용어                | 설명                                        |
| ------------------- | ------------------------------------------- |
| 루트 글 (Root Post) | parent_id가 NULL인 글, 스레드의 시작점      |
| 부모 글 (Parent)    | 현재 글이 연결된 직접 상위 글 (1단계 위)    |
| 조상 글 (Ancestors) | 루트부터 부모까지 모든 상위 글 목록         |
| 답글 (Replies)      | 현재 글을 부모로 가리키는 직접 하위 글 목록 |
| 스레드 (Thread)     | 부모-자식 관계로 연결된 글들의 집합         |
| 깊이 (Depth)        | 루트에서 현재 글까지의 거리 (루트=0)        |

### 관계 예시

```txt
A (루트)           ← depth: 0, parent: null
└── B              ← depth: 1, parent: A
    └── C          ← depth: 2, parent: B, ancestors: [A, B]
        └── D      ← depth: 3, parent: C, ancestors: [A, B, C]
```

## 데이터 모델

### Posts 테이블 확장

기존 posts 테이블에 다음 컬럼을 추가한다:

| 컬럼      | 타입    | 설명                           | NULL   |
| --------- | ------- | ------------------------------ | ------ |
| parent_id | string  | 부모 글의 ID                   | 허용   |
| depth     | integer | 스레드 깊이 (루트=0, 기본값 0) | 불허용 |

### 제약 조건

1. `parent_id`는 posts.id를 참조 (자기 참조 관계)
2. 자기 자신을 참조할 수 없음
3. 순환 참조 불가 (A → B → A)

## API 엔드포인트 (OpenAPI 3.1.0)

```yaml
paths:
  /posts:
    post:
      summary: 글 작성 (기존 확장)
      description: 새 글 작성 또는 기존 글에 답글 작성
      security:
        - bearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - content
              properties:
                content:
                  type: string
                  description: 글 내용
                  example: Hello, world!
                videoUrl:
                  type: string
                  format: uri
                  description: 동영상 URL (선택)
                parentId:
                  type: string
                  description: 부모 글 ID (선택, 답글 작성 시 사용)
                  example: 01JCSPOST0000000000000000
      responses:
        "201":
          description: 글 작성 성공
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Post"
        "401":
          description: 인증 필요
        "422":
          description: |
            유효성 검증 실패
            - parentId가 존재하지 않는 글을 참조
            - 10초 이내 중복 글 감지

  /posts/{id}:
    get:
      summary: 단일 글 조회 (신규)
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          example: 01JCSPOST0000000000000000
      responses:
        "200":
          description: 글 상세 정보
          content:
            application/json:
              schema:
                oneOf:
                  - $ref: "#/components/schemas/Post"
                  - $ref: "#/components/schemas/DeletedPost"
        "404":
          description: 글을 찾을 수 없음

    delete:
      summary: 글 삭제 (Soft Delete)
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        "204":
          description: 삭제 성공
        "401":
          description: 인증 필요
        "403":
          description: 권한 없음 (본인 글만 삭제 가능)
        "404":
          description: 글을 찾을 수 없음

  /posts/{id}/replies:
    get:
      summary: 답글 목록 조회 (신규)
      description: 특정 글의 직접 답글 목록 반환
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: 답글 목록
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/Post"
        "404":
          description: 글을 찾을 수 없음

  /posts/{id}/thread:
    get:
      summary: 스레드 조회 (신규)
      description: 상위 스레드(ancestors)와 답글(replies)을 함께 반환
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: 스레드 컨텍스트
          content:
            application/json:
              schema:
                type: object
                properties:
                  ancestors:
                    type: array
                    description: 루트부터 직접 부모까지의 글 목록
                    items:
                      oneOf:
                        - $ref: "#/components/schemas/Post"
                        - $ref: "#/components/schemas/DeletedPost"
                  post:
                    description: 요청한 글
                    oneOf:
                      - $ref: "#/components/schemas/Post"
                      - $ref: "#/components/schemas/DeletedPost"
                  replies:
                    type: array
                    description: 직접 답글 목록
                    items:
                      $ref: "#/components/schemas/Post"
        "404":
          description: 글을 찾을 수 없음

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  schemas:
    Post:
      type: object
      properties:
        id:
          type: string
          description: ULID 형식 글 ID
          example: 01JCSPOST0000000000000000
        user:
          type: object
          properties:
            id:
              type: string
            username:
              type: string
            nickname:
              type: string
            avatarUrl:
              type: string
              format: uri
              nullable: true
        content:
          type: string
          example: Hello, world!
        videoUrl:
          type: string
          format: uri
          nullable: true
        parentId:
          type: string
          nullable: true
          description: 부모 글 ID (답글인 경우)
        parent:
          $ref: "#/components/schemas/ParentPost"
          nullable: true
          description: 부모 글 정보 (parentId가 있을 때만)
        depth:
          type: integer
          description: 스레드 깊이 (루트에서 현재 글까지의 거리)
          example: 2
        repliesCount:
          type: integer
          description: 답글 수
          example: 5
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    ParentPost:
      type: object
      description: 부모 글 요약 정보 (스레드 힌트용)
      properties:
        id:
          type: string
        user:
          type: object
          properties:
            id:
              type: string
            username:
              type: string
            nickname:
              type: string
            avatarUrl:
              type: string
              nullable: true
        content:
          type: string
          nullable: true
          description: 삭제된 경우 null
        deleted:
          type: boolean
          description: 삭제 여부 (삭제된 경우에만 존재)
        parentId:
          type: string
          nullable: true
          description: 부모의 부모 ID (더 위에 있는지 힌트)

    DeletedPost:
      type: object
      description: Soft Delete된 글 (스레드 구조 유지)
      properties:
        id:
          type: string
        deleted:
          type: boolean
          example: true
        parentId:
          type: string
          nullable: true
        repliesCount:
          type: integer
```

## 카운터 캐싱

| 컬럼          | 설명       |
| ------------- | ---------- |
| replies_count | 자식 글 수 |

## 삭제 정책

- **Soft Delete**: deleted_at 컬럼으로 삭제 여부 표시
- 삭제된 글은 "삭제된 글입니다"로 표시되고 스레드 구조는 유지됨

## 성능 고려사항

1. `parent_id`에 인덱스 추가
2. 답글 목록 조회 시 페이지네이션
3. 스레드 깊이 제한 (예: 최대 100단계)

## 마이그레이션 계획

기존 데이터에는 영향 없음 (parent_id는 NULL 허용)
