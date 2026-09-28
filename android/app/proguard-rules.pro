-keep class * extends androidx.room.RoomDatabase {
    <init>();
}

-keep class * extends androidx.work.InputMerger {
    <init>();
}

-keep class androidx.work.impl.WorkDatabase {
    <init>();
}

-keep class androidx.work.impl.WorkDatabase_Impl {
    <init>();
}

-keep class androidx.startup.** { *; }