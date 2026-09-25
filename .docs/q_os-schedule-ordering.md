# q_os schedule ordering

This documents the default schedule configuration across `q_proc`, `q_shell`, and `q_term`.

Both `ShellPlugin::new` and `TerminalPlugin::new` can relocate their phases. The diagrams below show their defaults.

## Frame overview

```mermaid
flowchart TD
    First[First] --> PreUpdate[PreUpdate]
    PreUpdate --> FixedPreUpdate[FixedPreUpdate]
    FixedPreUpdate --> FixedUpdate[FixedUpdate]
    FixedUpdate --> FixedPostUpdate[FixedPostUpdate]
    FixedPostUpdate --> Update[Update]
    Update --> PostUpdate[PostUpdate]
    PostUpdate --> NextFirst[Next frame First]
```

`q_proc` installs its program chain in `PreUpdate`, `FixedPreUpdate`, `FixedUpdate`, `FixedPostUpdate`, `Update`, and `PostUpdate`.

## First

```mermaid
flowchart TD
    QueueInput[Process QueueInput] --> Cleanup[Process Cleanup]
```

`ProcessInputMsg` values emitted during one frame are retained until `QueueInput` demultiplexes them into process-local buffers during the next `First` schedule.

## Repeated process schedule

This chain runs in every supported program schedule:

```mermaid
flowchart TD
    RunPrograms[Process RunPrograms]
    RunPrograms --> ProgramBarrier[ApplyDeferred]
    ProgramBarrier --> RouteWrites[Process RouteWrites]
    RouteWrites --> ProcessCleanup[Process Cleanup]
```

The chain is installed in:

- `PreUpdate`
- `FixedPreUpdate`
- `FixedUpdate`
- `FixedPostUpdate`
- `Update`
- `PostUpdate`

## Default Update integration

```mermaid
flowchart TD
    TerminalInput[Terminal Input]

    TerminalInput --> TerminalMeasure[Terminal Measure]
    TerminalMeasure --> TerminalProcess[Terminal Process]

    TerminalInput --> ShellSpawn[Shell Spawn]
    ShellSpawn --> ShellForeground[Shell Foreground]
    ShellForeground --> SyncForeground[Shell IO SyncForeground]
    SyncForeground --> ForegroundBarrier[ApplyDeferred]

    ForegroundBarrier --> RunPrograms[Process RunPrograms]
    RunPrograms --> ProgramBarrier[ApplyDeferred]
    ProgramBarrier --> RouteWrites[Process RouteWrites]
    RouteWrites --> ProcessCleanup[Process Cleanup]

    ProcessCleanup --> ShellCleanup[Shell IO Cleanup]
    ShellCleanup --> CleanupBarrier[ApplyDeferred]
    CleanupBarrier --> ProcessOutput[Shell IO ProcessOutput]
    ProcessOutput --> TerminalProcess

    TerminalProcess --> TerminalReplies[Shell IO TerminalReplies]
    TerminalReplies --> TerminalRender[Terminal Render]
```

`Terminal Measure` and the shell/process branch may run concurrently after `Terminal Input`. They converge at `Terminal Process`.

The cleanup barrier makes process removal and foreground fallback visible before q_term applies terminal output admission. VT replies emitted by `Terminal Process` become `ProcessInputMsg` values in the same `Update`, then enter the destination process buffer during the next frame's `First` schedule.

## PostUpdate

Two independent chains run in `PostUpdate`:

```mermaid
flowchart TD
    RunPrograms[Process RunPrograms]
    RunPrograms --> ProgramBarrier[ApplyDeferred]
    ProgramBarrier --> RouteWrites[Process RouteWrites]
    RouteWrites --> ProcessCleanup[Process Cleanup]

    UiLayout[Bevy UI layout]
    UiLayout --> RefreshUi[Terminal Render refresh_ui]
```

The default shell I/O adapter runs in `Update`, not `PostUpdate`. Process output emitted during `PostUpdate` is therefore translated and processed during the following `Update`.
