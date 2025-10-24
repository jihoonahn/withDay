# WithDay Dependency Injection 가이드

## 📋 목차

1. [개요](#개요)
2. [아키텍처](#아키텍처)
3. [등록된 의존성](#등록된-의존성)
4. [사용 방법](#사용-방법)
5. [환경 설정](#환경-설정)

## 개요

WithDay 앱은 **Dependency Injection (DI)** 패턴을 사용하여 모듈 간 결합도를 낮추고 테스트 가능한 구조를 유지합니다.

### 핵심 컴포넌트

- **SupabaseCore**: 클라우드 데이터베이스 (온라인)
- **SwiftDataCore**: 로컬 데이터베이스 (오프라인)
- **DIContainer**: 의존성 관리 컨테이너

## 아키텍처

```
┌─────────────────────────────────────────┐
│             App Layer                    │
│  (SwiftUI Views, ViewModels)            │
└──────────────┬──────────────────────────┘
               │ resolve
               ▼
┌─────────────────────────────────────────┐
│         DIContainer                      │
│  (Dependency Registration)              │
└──────────┬────────────┬─────────────────┘
           │            │
           ▼            ▼
┌──────────────┐  ┌──────────────┐
│ SupabaseCore │  │ SwiftDataCore│
│  (클라우드)   │  │   (로컬)      │
└──────┬───────┘  └──────┬────────┘
       │                  │
       ▼                  ▼
┌──────────────┐  ┌──────────────┐
│  UseCase     │  │  Service     │
└──────┬───────┘  └──────────────┘
       │
       ▼
┌──────────────┐
│ Repository   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Service    │
└──────────────┘
```

## 등록된 의존성

### SupabaseCore (클라우드)

#### Services

```swift
SupabaseService              // Supabase 클라이언트
UserService                  // 사용자 인증 & 관리
AlarmService                 // 알람 CRUD
MemoService                  // 메모 CRUD
AlarmExecutionService        // 알람 실행 기록
MotionRawDataService         // 모션 센서 데이터
AchievementService           // 성취/경험치
```

#### Repositories

```swift
UserRepository               // 사용자 데이터 레포지토리
AlarmRepository              // 알람 데이터 레포지토리
MemoRepository               // 메모 데이터 레포지토리
AlarmExecutionRepository     // 알람 실행 레포지토리
MotionRawDataRepository      // 모션 데이터 레포지토리
AchievementRepository        // 성취 데이터 레포지토리
```

#### UseCases

```swift
UserUseCase                  // 사용자 비즈니스 로직
AlarmUseCase                 // 알람 비즈니스 로직
MemoUseCase                  // 메모 비즈니스 로직
AlarmExecutionUseCase        // 알람 실행 비즈니스 로직
MotionRawDataUseCase         // 모션 데이터 비즈니스 로직
AchievementUseCase           // 성취 비즈니스 로직
```

### SwiftDataCore (로컬)

#### Services

```swift
SwiftDataService             // ModelContainer 관리
AlarmService                 // 로컬 알람 CRUD
MemoService                  // 로컬 메모 CRUD
AlarmExecutionService        // 로컬 알람 실행 기록
MotionRawDataService         // 로컬 모션 데이터
AchievementService           // 로컬 성취 데이터
```

## 사용 방법

### 1. 기본 사용법

```swift
import Dependency

// DIContainer에서 의존성 가져오기
let alarmUseCase = DIContainer.shared.resolve(AlarmUseCase.self)

// UseCase 사용
let alarms = try await alarmUseCase.fetchAll(userId: userId)
```

### 2. Supabase (클라우드) 사용

#### 사용자 로그인

```swift
let userUseCase = DIContainer.shared.resolve(UserUseCase.self)

// OAuth 로그인
let user = try await userUseCase.login(
    provider: "google",
    email: "user@example.com",
    displayName: "홍길동"
)

// 현재 사용자 가져오기
let currentUser = try await userUseCase.getCurrentUser()
```

#### 알람 관리

```swift
let alarmUseCase = DIContainer.shared.resolve(AlarmUseCase.self)

// 알람 조회
let alarms = try await alarmUseCase.fetchAll(userId: userId)

// 알람 생성
let alarm = AlarmEntity(...)
try await alarmUseCase.create(alarm)

// 알람 토글
try await alarmUseCase.toggle(id: alarmId, isEnabled: true)
```

#### 메모 관리

```swift
let memoUseCase = DIContainer.shared.resolve(MemoUseCase.self)

// 메모 조회
let memos = try await memoUseCase.fetchAll(userId: userId)

// 메모 생성
let memo = MemoEntity(...)
try await memoUseCase.create(memo)
```

### 3. SwiftData (로컬) 사용

#### 로컬 알람 저장

```swift
import SwiftDataCoreInterface

let localAlarmService = DIContainer.shared.resolve(
    SwiftDataCoreInterface.AlarmService.self
)

// 로컬 알람 조회
let localAlarms = try await localAlarmService.fetchAlarms(userId: userId)

// 로컬에 알람 저장
let alarm = AlarmModel(...)
try await localAlarmService.saveAlarm(alarm)
```

### 4. SwiftUI View에서 사용

```swift
struct AlarmListView: View {
    @State private var alarms: [AlarmEntity] = []

    var body: some View {
        List(alarms) { alarm in
            Text(alarm.label ?? "알람")
        }
        .task {
            await loadAlarms()
        }
    }

    @MainActor
    private func loadAlarms() async {
        do {
            let alarmUseCase = DIContainer.shared.resolve(AlarmUseCase.self)
            let userUseCase = DIContainer.shared.resolve(UserUseCase.self)

            guard let user = try await userUseCase.getCurrentUser() else {
                return
            }

            alarms = try await alarmUseCase.fetchAll(userId: user.id)
        } catch {
            print("Error: \(error)")
        }
    }
}
```

### 5. 하이브리드 사용 (온라인 + 오프라인)

```swift
func syncData(userId: UUID) async throws {
    let cloudUseCase = DIContainer.shared.resolve(AlarmUseCase.self)
    let localService = DIContainer.shared.resolve(
        SwiftDataCoreInterface.AlarmService.self
    )

    do {
        // 온라인: 클라우드에서 데이터 가져오기
        let cloudAlarms = try await cloudUseCase.fetchAll(userId: userId)

        // 로컬에 백업
        for alarm in cloudAlarms {
            let localAlarm = AlarmModel(from: alarm)
            try await localService.saveAlarm(localAlarm)
        }

    } catch {
        // 오프라인: 로컬 데이터 사용
        let localAlarms = try await localService.fetchAlarms(userId: userId)
        // 로컬 데이터로 작업...
    }
}
```

## 환경 설정

### Supabase 환경변수 설정

앱 실행 전에 환경변수를 설정해야 합니다:

```bash
# Xcode Scheme에서 설정
Edit Scheme → Run → Arguments → Environment Variables

SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

또는 `.xcconfig` 파일에 추가:

```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### SwiftData 설정

SwiftData는 자동으로 로컬에 데이터베이스를 생성합니다. 추가 설정 필요 없음.

## 주의사항

### MainActor

SwiftDataCore의 모든 Service는 `@MainActor`에서 실행됩니다:

```swift
@MainActor
func useSwiftData() async {
    let service = DIContainer.shared.resolve(
        SwiftDataCoreInterface.AlarmService.self
    )
    // MainActor에서 실행됨
}
```

### 네임스페이스 충돌

SupabaseCore와 SwiftDataCore 모두 같은 이름의 Service를 가지므로 명확하게 구분:

```swift
// Supabase
let cloudService = DIContainer.shared.resolve(
    SupabaseCoreInterface.AlarmService.self
)

// SwiftData
let localService = DIContainer.shared.resolve(
    SwiftDataCoreInterface.AlarmService.self
)
```

### Entity ↔ Model 변환

- **Entity**: Domain 계층, 비즈니스 로직
- **Model**: SwiftData 모델, 로컬 저장

```swift
// Entity → Model
let model = AlarmModel(from: entity)

// Model → Entity
let entity = model.toEntity()
```

## 테스트

```swift
class AlarmUseCaseTests: XCTestCase {
    var container: DIContainer!

    override func setUp() {
        container = DIContainer()

        // Mock 등록
        container.register(AlarmRepository.self) {
            MockAlarmRepository()
        }

        container.register(AlarmUseCase.self) {
            AlarmUseCaseImpl(
                alarmRepository: container.resolve(AlarmRepository.self)
            )
        }
    }

    func testFetchAlarms() async throws {
        let useCase = container.resolve(AlarmUseCase.self)
        let alarms = try await useCase.fetchAll(userId: testUserId)

        XCTAssertEqual(alarms.count, 5)
    }
}
```

## 문제 해결

### "Factory for X not registered" 오류

→ `AppDependencies.setup()`이 호출되었는지 확인

### Supabase 연결 오류

→ 환경변수 `SUPABASE_URL`, `SUPABASE_ANON_KEY` 확인

### SwiftData 오류

→ `@MainActor`에서 호출하는지 확인

## 참고 자료

- [DependencyUsageExample.swift](Projects/App/Sources/Application/DependencyUsageExample.swift) - 실제 사용 예시
- [AppDependency.swift](Projects/App/Sources/Application/AppDependency.swift) - DI 설정
