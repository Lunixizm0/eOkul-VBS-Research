.class public final Lk2/a;
.super Ljava/lang/Object;
.source "SourceFile"


# instance fields
.field public final a:Ljava/nio/charset/Charset;

.field public final b:Landroid/content/Context;

.field public c:Ljava/lang/String;

.field public d:Ljava/util/Map;

.field public e:Ljava/lang/String;

.field public f:Landroid/content/SharedPreferences;

.field public g:LB1/a;

.field public h:Lg2/x;

.field public i:Ljava/lang/Boolean;


# direct methods
.method public constructor <init>(Landroid/content/Context;Ljava/util/HashMap;)V
    .locals 1

    .line 1
    .line 2
    .line 3
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    .line 4
    .line 5
    const/4 v0, 0x0

    const-string v0, "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg"

    .line 6
    .line 7
    iput-object v0, p0, Lk2/a;->c:Ljava/lang/String;

    .line 8
    .line 9
    const-string v0, "FlutterSecureStorage"

    .line 10
    .line 11
    iput-object v0, p0, Lk2/a;->e:Ljava/lang/String;

    .line 12
    .line 13
    sget-object v0, Ljava/lang/Boolean;->FALSE:Ljava/lang/Boolean;

    .line 14
    .line 15
    iput-object v0, p0, Lk2/a;->i:Ljava/lang/Boolean;

    .line 16
    .line 17
    iput-object p2, p0, Lk2/a;->d:Ljava/util/Map;

    .line 18
    .line 19
    .line 20
    invoke-virtual {p1}, Landroid/content/Context;->getApplicationContext()Landroid/content/Context;

    .line 21
    move-result-object p1

    .line 22
    .line 23
    iput-object p1, p0, Lk2/a;->b:Landroid/content/Context;

    .line 24
    .line 25
    sget-object p1, Ljava/nio/charset/StandardCharsets;->UTF_8:Ljava/nio/charset/Charset;

    .line 26
    .line 27
    iput-object p1, p0, Lk2/a;->a:Ljava/nio/charset/Charset;

    .line 28
    return-void
.end method


# virtual methods
.method public final a(Landroid/content/SharedPreferences;Lh0/b;)V
    .locals 4

    .line 1
    :try_start_0
    invoke-interface {p1}, Landroid/content/SharedPreferences;->getAll()Ljava/util/Map;

    .line 2
    .line 3
    .line 4
    move-result-object v0

    .line 5
    invoke-interface {v0}, Ljava/util/Map;->entrySet()Ljava/util/Set;

    .line 6
    .line 7
    .line 8
    move-result-object v0

    .line 9
    invoke-interface {v0}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    .line 10
    .line 11
    .line 12
    move-result-object v0

    .line 13
    :cond_0
    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    .line 14
    .line 15
    .line 16
    move-result v1

    .line 17
    if-eqz v1, :cond_1

    .line 18
    .line 19
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 20
    .line 21
    .line 22
    move-result-object v1

    .line 23
    check-cast v1, Ljava/util/Map$Entry;

    .line 24
    .line 25
    invoke-interface {v1}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    .line 26
    .line 27
    .line 28
    move-result-object v2

    .line 29
    invoke-interface {v1}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    .line 30
    .line 31
    .line 32
    move-result-object v1

    .line 33
    check-cast v1, Ljava/lang/String;

    .line 34
    .line 35
    instance-of v3, v2, Ljava/lang/String;

    .line 36
    .line 37
    if-eqz v3, :cond_0

    .line 38
    .line 39
    iget-object v3, p0, Lk2/a;->c:Ljava/lang/String;

    .line 40
    .line 41
    invoke-virtual {v1, v3}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 42
    .line 43
    .line 44
    move-result v3

    .line 45
    if-eqz v3, :cond_0

    .line 46
    .line 47
    check-cast v2, Ljava/lang/String;

    .line 48
    .line 49
    invoke-virtual {p0, v2}, Lk2/a;->b(Ljava/lang/String;)Ljava/lang/String;

    .line 50
    .line 51
    .line 52
    move-result-object v2

    .line 53
    invoke-virtual {p2}, Lh0/b;->edit()Landroid/content/SharedPreferences$Editor;

    .line 54
    .line 55
    .line 56
    move-result-object v3

    .line 57
    check-cast v3, Lh0/a;

    .line 58
    .line 59
    invoke-virtual {v3, v1, v2}, Lh0/a;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 60
    .line 61
    .line 62
    invoke-interface {v3}, Landroid/content/SharedPreferences$Editor;->apply()V

    .line 63
    .line 64
    .line 65
    invoke-interface {p1}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    .line 66
    .line 67
    .line 68
    move-result-object v2

    .line 69
    invoke-interface {v2, v1}, Landroid/content/SharedPreferences$Editor;->remove(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 70
    .line 71
    .line 72
    move-result-object v1

    .line 73
    invoke-interface {v1}, Landroid/content/SharedPreferences$Editor;->apply()V

    .line 74
    .line 75
    .line 76
    goto :goto_0

    .line 77
    :catch_0
    move-exception p1

    .line 78
    goto :goto_1

    .line 79
    :cond_1
    invoke-interface {p1}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    .line 80
    .line 81
    .line 82
    move-result-object p1

    .line 83
    iget-object p2, p0, Lk2/a;->h:Lg2/x;

    .line 84
    .line 85
    invoke-virtual {p2}, Ljava/lang/Object;->getClass()Ljava/lang/Class;

    .line 86
    .line 87
    .line 88
    const-string p2, "FlutterSecureSAlgorithmKey"

    .line 89
    .line 90
    invoke-interface {p1, p2}, Landroid/content/SharedPreferences$Editor;->remove(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 91
    .line 92
    .line 93
    const-string p2, "FlutterSecureSAlgorithmStorage"

    .line 94
    .line 95
    invoke-interface {p1, p2}, Landroid/content/SharedPreferences$Editor;->remove(Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 96
    .line 97
    .line 98
    invoke-interface {p1}, Landroid/content/SharedPreferences$Editor;->apply()V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 99
    .line 100
    .line 101
    goto :goto_2

    .line 102
    :goto_1
    const-string p2, "SecureStorageAndroid"

    .line 103
    .line 104
    const-string v0, "Data migration failed"

    .line 105
    .line 106
    invoke-static {p2, v0, p1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 107
    .line 108
    .line 109
    :goto_2
    return-void
.end method

.method public final b(Ljava/lang/String;)Ljava/lang/String;
    .locals 6

    .line 1
    if-nez p1, :cond_0

    .line 2
    .line 3
    const-string p1, ""

    .line 4
    return-object p1

    .line 5
    :cond_0
    iget-object v0, p0, Lk2/a;->g:LB1/a;

    if-nez v0, :cond_z

    if-nez p1, :cond_y

    const-string p1, ""

    :cond_y
    return-object p1

    :cond_z
    const/4 v0, 0x0

    .line 6
    invoke-static {p1, v0}, Landroid/util/Base64;->decode(Ljava/lang/String;I)[B

    .line 7
    .line 8
    .line 9
    move-result-object p1

    .line 10
    iget-object v1, p0, Lk2/a;->g:LB1/a;

    .line 11
    .line 12
    invoke-virtual {v1}, LB1/a;->O()I

    .line 13
    .line 14
    .line 15
    move-result v2

    .line 16
    new-array v3, v2, [B

    .line 17
    .line 18
    invoke-static {p1, v0, v3, v0, v2}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 19
    .line 20
    .line 21
    invoke-virtual {v1, v3}, LB1/a;->P([B)Ljava/security/spec/AlgorithmParameterSpec;

    .line 22
    .line 23
    .line 24
    move-result-object v3

    .line 25
    array-length v4, p1

    .line 26
    invoke-virtual {v1}, LB1/a;->O()I

    .line 27
    .line 28
    .line 29
    move-result v5

    .line 30
    sub-int/2addr v4, v5

    .line 31
    new-array v5, v4, [B

    .line 32
    .line 33
    invoke-static {p1, v2, v5, v0, v4}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 34
    .line 35
    .line 36
    const/4 p1, 0x2

    .line 37
    iget-object v0, v1, LB1/a;->l:Ljava/lang/Object;

    .line 38
    .line 39
    check-cast v0, Ljava/security/Key;

    .line 40
    .line 41
    iget-object v1, v1, LB1/a;->m:Ljava/lang/Object;

    .line 42
    .line 43
    check-cast v1, Ljavax/crypto/Cipher;

    .line 44
    .line 45
    invoke-virtual {v1, p1, v0, v3}, Ljavax/crypto/Cipher;->init(ILjava/security/Key;Ljava/security/spec/AlgorithmParameterSpec;)V

    .line 46
    .line 47
    .line 48
    invoke-virtual {v1, v5}, Ljavax/crypto/Cipher;->doFinal([B)[B

    .line 49
    .line 50
    .line 51
    move-result-object p1

    .line 52
    new-instance v0, Ljava/lang/String;

    .line 53
    .line 54
    iget-object v1, p0, Lk2/a;->a:Ljava/nio/charset/Charset;

    .line 55
    .line 56
    invoke-direct {v0, p1, v1}, Ljava/lang/String;-><init>([BLjava/nio/charset/Charset;)V

    .line 57
    .line 58
    .line 59
    return-object v0
.end method

.method public final c()V
    .locals 3

    invoke-virtual {p0}, Lk2/a;->d()V

    iget-object v0, p0, Lk2/a;->e:Ljava/lang/String;

    iget-object v1, p0, Lk2/a;->b:Landroid/content/Context;

    const/4 v2, 0x0

    invoke-virtual {v1, v0, v2}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    move-result-object v0

    iput-object v0, p0, Lk2/a;->f:Landroid/content/SharedPreferences;

    sget-object v0, Ljava/lang/Boolean;->TRUE:Ljava/lang/Boolean;

    iput-object v0, p0, Lk2/a;->i:Ljava/lang/Boolean;

    return-void
.end method

.method public final d()V
    .locals 2

    .line 1
    iget-object v0, p0, Lk2/a;->d:Ljava/util/Map;

    .line 2
    .line 3
    const-string v1, "sharedPreferencesName"

    .line 4
    .line 5
    invoke-interface {v0, v1}, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z

    .line 6
    .line 7
    .line 8
    move-result v0

    .line 9
    if-eqz v0, :cond_0

    .line 10
    .line 11
    iget-object v0, p0, Lk2/a;->d:Ljava/util/Map;

    .line 12
    .line 13
    invoke-interface {v0, v1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 14
    .line 15
    .line 16
    move-result-object v0

    .line 17
    check-cast v0, Ljava/lang/String;

    .line 18
    .line 19
    invoke-virtual {v0}, Ljava/lang/String;->isEmpty()Z

    .line 20
    .line 21
    .line 22
    move-result v0

    .line 23
    if-nez v0, :cond_0

    .line 24
    .line 25
    iget-object v0, p0, Lk2/a;->d:Ljava/util/Map;

    .line 26
    .line 27
    invoke-interface {v0, v1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 28
    .line 29
    .line 30
    move-result-object v0

    .line 31
    check-cast v0, Ljava/lang/String;

    .line 32
    .line 33
    iput-object v0, p0, Lk2/a;->e:Ljava/lang/String;

    .line 34
    .line 35
    :cond_0
    iget-object v0, p0, Lk2/a;->d:Ljava/util/Map;

    .line 36
    .line 37
    const-string v1, "preferencesKeyPrefix"

    .line 38
    .line 39
    invoke-interface {v0, v1}, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z

    .line 40
    .line 41
    .line 42
    move-result v0

    .line 43
    if-eqz v0, :cond_1

    .line 44
    .line 45
    iget-object v0, p0, Lk2/a;->d:Ljava/util/Map;

    .line 46
    .line 47
    invoke-interface {v0, v1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 48
    .line 49
    .line 50
    move-result-object v0

    .line 51
    check-cast v0, Ljava/lang/String;

    .line 52
    .line 53
    invoke-virtual {v0}, Ljava/lang/String;->isEmpty()Z

    .line 54
    .line 55
    .line 56
    move-result v0

    .line 57
    if-nez v0, :cond_1

    .line 58
    .line 59
    iget-object v0, p0, Lk2/a;->d:Ljava/util/Map;

    .line 60
    .line 61
    invoke-interface {v0, v1}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 62
    .line 63
    .line 64
    move-result-object v0

    .line 65
    check-cast v0, Ljava/lang/String;

    .line 66
    .line 67
    iput-object v0, p0, Lk2/a;->c:Ljava/lang/String;

    .line 68
    .line 69
    :cond_1
    return-void
.end method

.method public final e()Z
    .locals 3

    .line 1
    iget-object v0, p0, Lk2/a;->i:Ljava/lang/Boolean;

    .line 2
    .line 3
    invoke-virtual {v0}, Ljava/lang/Boolean;->booleanValue()Z

    .line 4
    .line 5
    .line 6
    move-result v0

    .line 7
    const/4 v1, 0x0

    .line 8
    if-eqz v0, :cond_0

    const/4 v1, 0x1

    .line 9
    .line 10
    return v1

    .line 11
    :cond_0
    iget-object v0, p0, Lk2/a;->d:Ljava/util/Map;

    .line 12
    .line 13
    const-string v2, "encryptedSharedPreferences"

    .line 14
    .line 15
    invoke-interface {v0, v2}, Ljava/util/Map;->containsKey(Ljava/lang/Object;)Z

    .line 16
    .line 17
    .line 18
    move-result v0

    .line 19
    if-eqz v0, :cond_1

    .line 20
    .line 21
    iget-object v0, p0, Lk2/a;->d:Ljava/util/Map;

    .line 22
    .line 23
    invoke-interface {v0, v2}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 24
    .line 25
    .line 26
    move-result-object v0

    .line 27
    const-string v2, "true"

    .line 28
    .line 29
    invoke-virtual {v0, v2}, Ljava/lang/Object;->equals(Ljava/lang/Object;)Z

    .line 30
    .line 31
    .line 32
    move-result v0

    .line 33
    if-eqz v0, :cond_1

    .line 34
    .line 35
    const/4 v1, 0x1

    .line 36
    :cond_1
    return v1
.end method

.method public final f(Landroid/content/SharedPreferences;)V
    .locals 10

    .line 1
    .line 2
    new-instance v0, Lg2/x;

    .line 3
    .line 4
    iget-object v1, p0, Lk2/a;->d:Ljava/util/Map;

    .line 5
    .line 6
    .line 7
    invoke-direct {v0}, Ljava/lang/Object;-><init>()V

    .line 8
    .line 9
    const-string v2, "FlutterSecureSAlgorithmKey"

    .line 10
    .line 11
    const-string v3, "RSA_ECB_PKCS1Padding"

    .line 12
    .line 13
    .line 14
    invoke-interface {p1, v2, v3}, Landroid/content/SharedPreferences;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 15
    move-result-object v2

    .line 16
    .line 17
    .line 18
    invoke-static {v2}, Ll2/a;->valueOf(Ljava/lang/String;)Ll2/a;

    .line 19
    move-result-object v2

    .line 20
    .line 21
    iput-object v2, v0, Lg2/x;->k:Ljava/lang/Object;

    .line 22
    .line 23
    const-string v2, "FlutterSecureSAlgorithmStorage"

    .line 24
    .line 25
    const-string v4, "AES_CBC_PKCS7Padding"

    .line 26
    .line 27
    .line 28
    invoke-interface {p1, v2, v4}, Landroid/content/SharedPreferences;->getString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 29
    move-result-object v2

    .line 30
    .line 31
    .line 32
    invoke-static {v2}, Ll2/c;->valueOf(Ljava/lang/String;)Ll2/c;

    .line 33
    move-result-object v2

    .line 34
    .line 35
    iput-object v2, v0, Lg2/x;->l:Ljava/lang/Object;

    .line 36
    .line 37
    const-string v2, "keyCipherAlgorithm"

    .line 38
    .line 39
    .line 40
    invoke-interface {v1, v2}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 41
    move-result-object v2

    .line 42
    .line 43
    if-eqz v2, :cond_0

    .line 44
    .line 45
    .line 46
    invoke-virtual {v2}, Ljava/lang/Object;->toString()Ljava/lang/String;

    .line 47
    move-result-object v3

    .line 48
    .line 49
    .line 50
    :cond_0
    invoke-static {v3}, Ll2/a;->valueOf(Ljava/lang/String;)Ll2/a;

    .line 51
    move-result-object v2

    .line 52
    .line 53
    iget v3, v2, Ll2/a;->l:I

    .line 54
    .line 55
    sget v5, Landroid/os/Build$VERSION;->SDK_INT:I

    .line 56
    .line 57
    if-gt v3, v5, :cond_1

    .line 58
    goto :goto_0

    .line 59
    .line 60
    :cond_1
    sget-object v2, Ll2/a;->m:Ll2/a;

    .line 61
    .line 62
    :goto_0
    iput-object v2, v0, Lg2/x;->m:Ljava/lang/Object;

    .line 63
    .line 64
    const-string v2, "storageCipherAlgorithm"

    .line 65
    .line 66
    .line 67
    invoke-interface {v1, v2}, Ljava/util/Map;->get(Ljava/lang/Object;)Ljava/lang/Object;

    .line 68
    move-result-object v1

    .line 69
    .line 70
    if-eqz v1, :cond_2

    .line 71
    .line 72
    .line 73
    invoke-virtual {v1}, Ljava/lang/Object;->toString()Ljava/lang/String;

    .line 74
    move-result-object v4

    .line 75
    .line 76
    .line 77
    :cond_2
    invoke-static {v4}, Ll2/c;->valueOf(Ljava/lang/String;)Ll2/c;

    .line 78
    move-result-object v1

    .line 79
    .line 80
    iget v2, v1, Ll2/c;->l:I

    .line 81
    .line 82
    if-gt v2, v5, :cond_3

    .line 83
    goto :goto_1

    .line 84
    .line 85
    :cond_3
    sget-object v1, Ll2/c;->m:Ll2/c;

    .line 86
    .line 87
    :goto_1
    iput-object v1, v0, Lg2/x;->n:Ljava/lang/Object;

    .line 88
    .line 89
    iput-object v0, p0, Lk2/a;->h:Lg2/x;

    .line 90
    .line 91
    .line 92
    invoke-virtual {p0}, Lk2/a;->e()Z

    .line 93
    move-result v0

    .line 94
    .line 95
    iget-object v1, p0, Lk2/a;->b:Landroid/content/Context;

    .line 96
    .line 97
    if-eqz v0, :cond_4

    .line 98
    .line 99
    iget-object p1, p0, Lk2/a;->h:Lg2/x;

    .line 100
    .line 101
    iget-object v0, p1, Lg2/x;->k:Ljava/lang/Object;

    .line 102
    .line 103
    check-cast v0, Ll2/a;

    .line 104
    .line 105
    iget-object v0, v0, Ll2/a;->k:Li2/b;

    .line 106
    .line 107
    .line 108
    invoke-virtual {v0, v1}, Li2/b;->d(Landroid/content/Context;)Lcom/google/android/gms/internal/measurement/L1;

    .line 109
    move-result-object v0

    .line 110
    .line 111
    iget-object p1, p1, Lg2/x;->l:Ljava/lang/Object;

    .line 112
    .line 113
    check-cast p1, Ll2/c;

    .line 114
    .line 115
    iget-object p1, p1, Ll2/c;->k:Li2/b;

    .line 116
    .line 117
    .line 118
    invoke-virtual {p1, v1, v0}, Li2/b;->a(Landroid/content/Context;Lcom/google/android/gms/internal/measurement/L1;)LB1/a;

    .line 119
    move-result-object p1

    .line 120
    .line 121
    iput-object p1, p0, Lk2/a;->g:LB1/a;

    .line 122
    .line 123
    goto/16 :goto_6

    .line 124
    .line 125
    :cond_4
    iget-object v0, p0, Lk2/a;->h:Lg2/x;

    .line 126
    .line 127
    iget-object v2, v0, Lg2/x;->k:Ljava/lang/Object;

    .line 128
    .line 129
    check-cast v2, Ll2/a;

    .line 130
    .line 131
    iget-object v3, v0, Lg2/x;->l:Ljava/lang/Object;

    .line 132
    .line 133
    check-cast v3, Ll2/c;

    .line 134
    .line 135
    iget-object v4, v0, Lg2/x;->m:Ljava/lang/Object;

    .line 136
    .line 137
    check-cast v4, Ll2/a;

    .line 138
    .line 139
    iget-object v5, v0, Lg2/x;->n:Ljava/lang/Object;

    .line 140
    .line 141
    check-cast v5, Ll2/c;

    .line 142
    .line 143
    if-ne v2, v4, :cond_6

    .line 144
    .line 145
    if-eq v3, v5, :cond_5

    .line 146
    goto :goto_2

    .line 147
    .line 148
    :cond_5
    iget-object p1, v4, Ll2/a;->k:Li2/b;

    .line 149
    .line 150
    .line 151
    invoke-virtual {p1, v1}, Li2/b;->d(Landroid/content/Context;)Lcom/google/android/gms/internal/measurement/L1;

    .line 152
    move-result-object p1

    .line 153
    .line 154
    iget-object v0, v5, Ll2/c;->k:Li2/b;

    .line 155
    .line 156
    .line 157
    invoke-virtual {v0, v1, p1}, Li2/b;->a(Landroid/content/Context;Lcom/google/android/gms/internal/measurement/L1;)LB1/a;

    .line 158
    move-result-object p1

    .line 159
    .line 160
    iput-object p1, p0, Lk2/a;->g:LB1/a;

    .line 161
    .line 162
    goto/16 :goto_6

    .line 163
    .line 164
    :cond_6
    :goto_2
    :try_start_0
    iget-object v2, v2, Ll2/a;->k:Li2/b;

    .line 165
    .line 166
    .line 167
    invoke-virtual {v2, v1}, Li2/b;->d(Landroid/content/Context;)Lcom/google/android/gms/internal/measurement/L1;

    .line 168
    move-result-object v2

    .line 169
    .line 170
    iget-object v6, v3, Ll2/c;->k:Li2/b;

    .line 171
    .line 172
    .line 173
    invoke-virtual {v6, v1, v2}, Li2/b;->a(Landroid/content/Context;Lcom/google/android/gms/internal/measurement/L1;)LB1/a;

    .line 174
    move-result-object v2

    .line 175
    .line 176
    iput-object v2, p0, Lk2/a;->g:LB1/a;

    .line 177
    .line 178
    new-instance v2, Ljava/util/HashMap;

    .line 179
    .line 180
    .line 181
    invoke-direct {v2}, Ljava/util/HashMap;-><init>()V

    .line 182
    .line 183
    .line 184
    invoke-interface {p1}, Landroid/content/SharedPreferences;->getAll()Ljava/util/Map;

    .line 185
    move-result-object v6

    .line 186
    .line 187
    .line 188
    invoke-interface {v6}, Ljava/util/Map;->entrySet()Ljava/util/Set;

    .line 189
    move-result-object v6

    .line 190
    .line 191
    .line 192
    invoke-interface {v6}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    .line 193
    move-result-object v6

    .line 194
    .line 195
    .line 196
    :cond_7
    :goto_3
    invoke-interface {v6}, Ljava/util/Iterator;->hasNext()Z

    .line 197
    move-result v7

    .line 198
    .line 199
    if-eqz v7, :cond_8

    .line 200
    .line 201
    .line 202
    invoke-interface {v6}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 203
    move-result-object v7

    .line 204
    .line 205
    check-cast v7, Ljava/util/Map$Entry;

    .line 206
    .line 207
    .line 208
    invoke-interface {v7}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    .line 209
    move-result-object v8

    .line 210
    .line 211
    .line 212
    invoke-interface {v7}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    .line 213
    move-result-object v7

    .line 214
    .line 215
    check-cast v7, Ljava/lang/String;

    .line 216
    .line 217
    instance-of v9, v8, Ljava/lang/String;

    .line 218
    .line 219
    if-eqz v9, :cond_7

    .line 220
    .line 221
    iget-object v9, p0, Lk2/a;->c:Ljava/lang/String;

    .line 222
    .line 223
    .line 224
    invoke-virtual {v7, v9}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 225
    move-result v9

    .line 226
    .line 227
    if-eqz v9, :cond_7

    .line 228
    .line 229
    check-cast v8, Ljava/lang/String;

    .line 230
    .line 231
    .line 232
    invoke-virtual {p0, v8}, Lk2/a;->b(Ljava/lang/String;)Ljava/lang/String;

    .line 233
    move-result-object v8

    .line 234
    .line 235
    .line 236
    invoke-virtual {v2, v7, v8}, Ljava/util/HashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 237
    goto :goto_3

    .line 238
    :catch_0
    move-exception p1

    .line 239
    goto :goto_5

    .line 240
    .line 241
    :cond_8
    iget-object v6, v4, Ll2/a;->k:Li2/b;

    .line 242
    .line 243
    .line 244
    invoke-virtual {v6, v1}, Li2/b;->d(Landroid/content/Context;)Lcom/google/android/gms/internal/measurement/L1;

    .line 245
    move-result-object v6

    .line 246
    .line 247
    iget-object v7, v5, Ll2/c;->k:Li2/b;

    .line 248
    .line 249
    .line 250
    invoke-virtual {v7, v1, v6}, Li2/b;->a(Landroid/content/Context;Lcom/google/android/gms/internal/measurement/L1;)LB1/a;

    .line 251
    move-result-object v6

    .line 252
    .line 253
    iput-object v6, p0, Lk2/a;->g:LB1/a;

    .line 254
    .line 255
    .line 256
    invoke-interface {p1}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    .line 257
    move-result-object p1

    .line 258
    .line 259
    .line 260
    invoke-virtual {v2}, Ljava/util/HashMap;->entrySet()Ljava/util/Set;

    .line 261
    move-result-object v2

    .line 262
    .line 263
    .line 264
    invoke-interface {v2}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    .line 265
    move-result-object v2

    .line 266
    .line 267
    .line 268
    :goto_4
    invoke-interface {v2}, Ljava/util/Iterator;->hasNext()Z

    .line 269
    move-result v6

    .line 270
    .line 271
    if-eqz v6, :cond_9

    .line 272
    .line 273
    .line 274
    invoke-interface {v2}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 275
    move-result-object v6

    .line 276
    .line 277
    check-cast v6, Ljava/util/Map$Entry;

    .line 278
    .line 279
    iget-object v7, p0, Lk2/a;->g:LB1/a;

    .line 280
    .line 281
    .line 282
    invoke-interface {v6}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    .line 283
    move-result-object v8

    .line 284
    .line 285
    check-cast v8, Ljava/lang/String;

    .line 286
    .line 287
    iget-object v9, p0, Lk2/a;->a:Ljava/nio/charset/Charset;

    .line 288
    .line 289
    .line 290
    invoke-virtual {v8, v9}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    .line 291
    move-result-object v8

    .line 292
    .line 293
    .line 294
    invoke-virtual {v7, v8}, LB1/a;->D([B)[B

    .line 295
    move-result-object v7

    .line 296
    .line 297
    .line 298
    invoke-interface {v6}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    .line 299
    move-result-object v6

    .line 300
    .line 301
    check-cast v6, Ljava/lang/String;

    .line 302
    const/4 v8, 0x0

    .line 303
    .line 304
    .line 305
    invoke-static {v7, v8}, Landroid/util/Base64;->encodeToString([BI)Ljava/lang/String;

    .line 306
    move-result-object v7

    .line 307
    .line 308
    .line 309
    invoke-interface {p1, v6, v7}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 310
    goto :goto_4

    .line 311
    .line 312
    .line 313
    :cond_9
    invoke-virtual {v4}, Ljava/lang/Enum;->name()Ljava/lang/String;

    .line 314
    move-result-object v2

    .line 315
    .line 316
    const/4 v4, 0x0

    const-string v4, "FlutterSecureSAlgorithmKey"

    .line 317
    .line 318
    .line 319
    invoke-interface {p1, v4, v2}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 320
    .line 321
    .line 322
    invoke-virtual {v5}, Ljava/lang/Enum;->name()Ljava/lang/String;

    .line 323
    move-result-object v2

    .line 324
    .line 325
    const-string v4, "FlutterSecureSAlgorithmStorage"

    .line 326
    .line 327
    .line 328
    invoke-interface {p1, v4, v2}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 329
    .line 330
    .line 331
    invoke-interface {p1}, Landroid/content/SharedPreferences$Editor;->apply()V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    .line 332
    goto :goto_6

    .line 333
    .line 334
    :goto_5
    const-string v2, "SecureStorageAndroid"

    .line 335
    .line 336
    const-string v4, "re-encryption failed"

    .line 337
    .line 338
    .line 339
    invoke-static {v2, v4, p1}, Landroid/util/Log;->e(Ljava/lang/String;Ljava/lang/String;Ljava/lang/Throwable;)I

    .line 340
    .line 341
    iget-object p1, v0, Lg2/x;->k:Ljava/lang/Object;

    .line 342
    .line 343
    check-cast p1, Ll2/a;

    .line 344
    .line 345
    iget-object p1, p1, Ll2/a;->k:Li2/b;

    .line 346
    .line 347
    .line 348
    invoke-virtual {p1, v1}, Li2/b;->d(Landroid/content/Context;)Lcom/google/android/gms/internal/measurement/L1;

    .line 349
    move-result-object p1

    .line 350
    .line 351
    iget-object v0, v3, Ll2/c;->k:Li2/b;

    .line 352
    .line 353
    .line 354
    invoke-virtual {v0, v1, p1}, Li2/b;->a(Landroid/content/Context;Lcom/google/android/gms/internal/measurement/L1;)LB1/a;

    .line 355
    move-result-object p1

    .line 356
    .line 357
    iput-object p1, p0, Lk2/a;->g:LB1/a;

    .line 358
    :goto_6
    return-void
.end method

.method public final g(Landroid/content/Context;)Lh0/b;
    .locals 6

    .line 1
    .line 2
    .line 3
    invoke-virtual {p1}, Landroid/content/Context;->getApplicationContext()Landroid/content/Context;

    .line 4
    .line 5
    const-string v0, "_androidx_security_master_key_"

    .line 6
    .line 7
    new-instance v1, Landroid/security/keystore/KeyGenParameterSpec$Builder;

    .line 8
    .line 9
    const-string v2, "_androidx_security_master_key_"

    .line 10
    const/4 v3, 0x3

    .line 11
    .line 12
    .line 13
    invoke-direct {v1, v2, v3}, Landroid/security/keystore/KeyGenParameterSpec$Builder;-><init>(Ljava/lang/String;I)V

    .line 14
    .line 15
    const-string v2, "NoPadding"

    .line 16
    .line 17
    .line 18
    filled-new-array {v2}, [Ljava/lang/String;

    .line 19
    move-result-object v2

    .line 20
    .line 21
    .line 22
    invoke-virtual {v1, v2}, Landroid/security/keystore/KeyGenParameterSpec$Builder;->setEncryptionPaddings([Ljava/lang/String;)Landroid/security/keystore/KeyGenParameterSpec$Builder;

    .line 23
    move-result-object v1

    .line 24
    .line 25
    const-string v2, "GCM"

    .line 26
    .line 27
    .line 28
    filled-new-array {v2}, [Ljava/lang/String;

    .line 29
    move-result-object v2

    .line 30
    .line 31
    .line 32
    invoke-virtual {v1, v2}, Landroid/security/keystore/KeyGenParameterSpec$Builder;->setBlockModes([Ljava/lang/String;)Landroid/security/keystore/KeyGenParameterSpec$Builder;

    .line 33
    move-result-object v1

    .line 34
    .line 35
    const/16 v2, 0x100

    .line 36
    .line 37
    .line 38
    invoke-virtual {v1, v2}, Landroid/security/keystore/KeyGenParameterSpec$Builder;->setKeySize(I)Landroid/security/keystore/KeyGenParameterSpec$Builder;

    .line 39
    move-result-object v1

    .line 40
    .line 41
    .line 42
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec$Builder;->build()Landroid/security/keystore/KeyGenParameterSpec;

    .line 43
    move-result-object v1

    .line 44
    .line 45
    .line 46
    invoke-static {v1}, Lh0/c;->a(Landroid/security/keystore/KeyGenParameterSpec;)Ljava/lang/String;

    .line 47
    move-result-object v4

    .line 48
    .line 49
    .line 50
    invoke-virtual {v0, v4}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    .line 51
    move-result v0

    .line 52
    .line 53
    if-eqz v0, :cond_b

    .line 54
    .line 55
    if-eqz v1, :cond_a

    .line 56
    .line 57
    sget-object v0, Lh0/d;->a:Ljava/lang/Object;

    .line 58
    .line 59
    .line 60
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getKeySize()I

    .line 61
    move-result v0

    .line 62
    .line 63
    if-ne v0, v2, :cond_9

    .line 64
    .line 65
    .line 66
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getBlockModes()[Ljava/lang/String;

    .line 67
    move-result-object v0

    .line 68
    .line 69
    const-string v2, "GCM"

    .line 70
    .line 71
    .line 72
    filled-new-array {v2}, [Ljava/lang/String;

    .line 73
    move-result-object v2

    .line 74
    .line 75
    .line 76
    invoke-static {v0, v2}, Ljava/util/Arrays;->equals([Ljava/lang/Object;[Ljava/lang/Object;)Z

    .line 77
    move-result v0

    .line 78
    .line 79
    if-eqz v0, :cond_8

    .line 80
    .line 81
    .line 82
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getPurposes()I

    .line 83
    move-result v0

    .line 84
    .line 85
    if-ne v0, v3, :cond_7

    .line 86
    .line 87
    .line 88
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getEncryptionPaddings()[Ljava/lang/String;

    .line 89
    move-result-object v0

    .line 90
    .line 91
    const-string v2, "NoPadding"

    .line 92
    .line 93
    .line 94
    filled-new-array {v2}, [Ljava/lang/String;

    .line 95
    move-result-object v2

    .line 96
    .line 97
    .line 98
    invoke-static {v0, v2}, Ljava/util/Arrays;->equals([Ljava/lang/Object;[Ljava/lang/Object;)Z

    .line 99
    move-result v0

    .line 100
    .line 101
    if-eqz v0, :cond_6

    .line 102
    .line 103
    .line 104
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->isUserAuthenticationRequired()Z

    .line 105
    move-result v0

    .line 106
    .line 107
    if-eqz v0, :cond_1

    .line 108
    .line 109
    .line 110
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getUserAuthenticationValidityDurationSeconds()I

    .line 111
    move-result v0

    .line 112
    const/4 v2, 0x1

    .line 113
    .line 114
    if-lt v0, v2, :cond_0

    .line 115
    goto :goto_0

    .line 116
    .line 117
    :cond_0
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 118
    .line 119
    const-string v0, "per-operation authentication is not supported (UserAuthenticationValidityDurationSeconds must be >0)"

    .line 120
    .line 121
    .line 122
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 123
    throw p1

    .line 124
    .line 125
    :cond_1
    :goto_0
    sget-object v0, Lh0/d;->a:Ljava/lang/Object;

    .line 126
    monitor-enter v0

    .line 127
    .line 128
    .line 129
    :try_start_0
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getKeystoreAlias()Ljava/lang/String;

    .line 130
    move-result-object v2

    .line 131
    .line 132
    const-string v3, "AndroidKeyStore"

    .line 133
    .line 134
    .line 135
    invoke-static {v3}, Ljava/security/KeyStore;->getInstance(Ljava/lang/String;)Ljava/security/KeyStore;

    .line 136
    move-result-object v3

    .line 137
    const/4 v4, 0x0

    .line 138
    .line 139
    .line 140
    invoke-virtual {v3, v4}, Ljava/security/KeyStore;->load(Ljava/security/KeyStore$LoadStoreParameter;)V

    .line 141
    .line 142
    .line 143
    invoke-virtual {v3, v2}, Ljava/security/KeyStore;->containsAlias(Ljava/lang/String;)Z

    .line 144
    move-result v2
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catchall_2

    .line 145
    .line 146
    if-nez v2, :cond_2

    .line 147
    .line 148
    :try_start_1
    const-string v2, "AES"

    .line 149
    .line 150
    const-string v3, "AndroidKeyStore"

    .line 151
    .line 152
    .line 153
    invoke-static {v2, v3}, Ljavax/crypto/KeyGenerator;->getInstance(Ljava/lang/String;Ljava/lang/String;)Ljavax/crypto/KeyGenerator;

    .line 154
    move-result-object v2

    .line 155
    .line 156
    .line 157
    invoke-virtual {v2, v1}, Ljavax/crypto/KeyGenerator;->init(Ljava/security/spec/AlgorithmParameterSpec;)V

    .line 158
    .line 159
    .line 160
    invoke-virtual {v2}, Ljavax/crypto/KeyGenerator;->generateKey()Ljavax/crypto/SecretKey;
    :try_end_1
    .catch Ljava/security/ProviderException; {:try_start_1 .. :try_end_1} :catch_0
    .catchall {:try_start_1 .. :try_end_1} :catchall_2

    .line 161
    goto :goto_1

    .line 162
    :catch_0
    move-exception p1

    .line 163
    .line 164
    :try_start_2
    new-instance v1, Ljava/security/GeneralSecurityException;

    .line 165
    .line 166
    .line 167
    invoke-virtual {p1}, Ljava/lang/Throwable;->getMessage()Ljava/lang/String;

    .line 168
    move-result-object v2

    .line 169
    .line 170
    .line 171
    invoke-direct {v1, v2, p1}, Ljava/security/GeneralSecurityException;-><init>(Ljava/lang/String;Ljava/lang/Throwable;)V

    .line 172
    throw v1

    .line 173
    :cond_2
    :goto_1
    monitor-exit v0
    :try_end_2
    .catchall {:try_start_2 .. :try_end_2} :catchall_2

    .line 174
    .line 175
    .line 176
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getKeystoreAlias()Ljava/lang/String;

    .line 177
    move-result-object v0

    .line 178
    .line 179
    iget-object v1, p0, Lk2/a;->e:Ljava/lang/String;

    .line 180
    .line 181
    .line 182
    invoke-static {}, Ly1/e;->a()V

    .line 183
    .line 184
    .line 185
    invoke-static {}, Lu1/a;->a()V

    .line 186
    .line 187
    .line 188
    invoke-virtual {p1}, Landroid/content/Context;->getApplicationContext()Landroid/content/Context;

    .line 189
    move-result-object p1

    .line 190
    .line 191
    new-instance v2, Ll/w1;

    .line 192
    .line 193
    .line 194
    invoke-direct {v2}, Ll/w1;-><init>()V

    .line 195
    .line 196
    const-string v3, "AES256_SIV"

    .line 197
    .line 198
    .line 199
    invoke-static {v3}, Lt1/b;->a(Ljava/lang/String;)Lt1/g;

    .line 200
    move-result-object v3

    .line 201
    .line 202
    iput-object v3, v2, Ll/w1;->p:Ljava/lang/Object;

    .line 203
    .line 204
    const-string v3, "__androidx_security_crypto_encrypted_prefs_key_keyset__"

    .line 205
    .line 206
    if-eqz p1, :cond_5

    .line 207
    .line 208
    iput-object p1, v2, Ll/w1;->k:Ljava/lang/Object;

    .line 209
    .line 210
    iput-object v3, v2, Ll/w1;->l:Ljava/lang/Object;

    .line 211
    .line 212
    iput-object v1, v2, Ll/w1;->m:Ljava/lang/Object;

    .line 213
    .line 214
    const-string v3, "android-keystore://"

    .line 215
    .line 216
    .line 217
    invoke-static {v3, v0}, Lcom/google/android/gms/internal/measurement/D2;->n(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 218
    move-result-object v4

    .line 219
    .line 220
    const/4 v5, 0x0

    const-string v5, "android-keystore://"

    .line 221
    .line 222
    .line 223
    invoke-virtual {v4, v5}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 224
    move-result v5

    .line 225
    .line 226
    if-eqz v5, :cond_4

    .line 227
    .line 228
    iput-object v4, v2, Ll/w1;->n:Ljava/lang/Object;

    .line 229
    .line 230
    .line 231
    invoke-virtual {v2}, Ll/w1;->a()Lz1/a;

    .line 232
    move-result-object v2

    .line 233
    monitor-enter v2

    .line 234
    .line 235
    :try_start_3
    iget-object v4, v2, Lz1/a;->a:Lt1/f;

    .line 236
    .line 237
    .line 238
    invoke-virtual {v4}, Lt1/f;->c()Ls2/x;

    .line 239
    move-result-object v4
    :try_end_3
    .catchall {:try_start_3 .. :try_end_3} :catchall_1

    .line 240
    monitor-exit v2

    .line 241
    .line 242
    new-instance v2, Ll/w1;

    .line 243
    .line 244
    .line 245
    invoke-direct {v2}, Ll/w1;-><init>()V

    .line 246
    .line 247
    const-string v5, "AES256_GCM"

    .line 248
    .line 249
    .line 250
    invoke-static {v5}, Lt1/b;->a(Ljava/lang/String;)Lt1/g;

    .line 251
    move-result-object v5

    .line 252
    .line 253
    iput-object v5, v2, Ll/w1;->p:Ljava/lang/Object;

    .line 254
    .line 255
    const-string v5, "__androidx_security_crypto_encrypted_prefs_value_keyset__"

    .line 256
    .line 257
    iput-object p1, v2, Ll/w1;->k:Ljava/lang/Object;

    .line 258
    .line 259
    iput-object v5, v2, Ll/w1;->l:Ljava/lang/Object;

    .line 260
    .line 261
    iput-object v1, v2, Ll/w1;->m:Ljava/lang/Object;

    .line 262
    .line 263
    .line 264
    invoke-static {v3, v0}, Lcom/google/android/gms/internal/measurement/D2;->n(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 265
    move-result-object v0

    .line 266
    .line 267
    const-string v3, "android-keystore://"

    .line 268
    .line 269
    .line 270
    invoke-virtual {v0, v3}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    .line 271
    move-result v3

    .line 272
    .line 273
    if-eqz v3, :cond_3

    .line 274
    .line 275
    iput-object v0, v2, Ll/w1;->n:Ljava/lang/Object;

    .line 276
    .line 277
    .line 278
    invoke-virtual {v2}, Ll/w1;->a()Lz1/a;

    .line 279
    move-result-object v0

    .line 280
    monitor-enter v0

    .line 281
    .line 282
    :try_start_4
    iget-object v2, v0, Lz1/a;->a:Lt1/f;

    .line 283
    .line 284
    .line 285
    invoke-virtual {v2}, Lt1/f;->c()Ls2/x;

    .line 286
    move-result-object v2
    :try_end_4
    .catchall {:try_start_4 .. :try_end_4} :catchall_0

    .line 287
    monitor-exit v0

    .line 288
    .line 289
    const-class v0, Lt1/c;

    .line 290
    .line 291
    .line 292
    invoke-virtual {v4, v0}, Ls2/x;->g(Ljava/lang/Class;)Ljava/lang/Object;

    .line 293
    move-result-object v0

    .line 294
    .line 295
    check-cast v0, Lt1/c;

    .line 296
    .line 297
    const-class v3, Lt1/a;

    .line 298
    .line 299
    .line 300
    invoke-virtual {v2, v3}, Ls2/x;->g(Ljava/lang/Class;)Ljava/lang/Object;

    .line 301
    move-result-object v2

    .line 302
    .line 303
    check-cast v2, Lt1/a;

    .line 304
    .line 305
    new-instance v3, Lh0/b;

    .line 306
    const/4 v4, 0x0

    .line 307
    .line 308
    .line 309
    invoke-virtual {p1, v1, v4}, Landroid/content/Context;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;

    .line 310
    move-result-object p1

    .line 311
    .line 312
    .line 313
    invoke-direct {v3, v1, p1, v2, v0}, Lh0/b;-><init>(Ljava/lang/String;Landroid/content/SharedPreferences;Lt1/a;Lt1/c;)V

    .line 314
    return-object v3

    .line 315
    :catchall_0
    move-exception p1

    .line 316
    :try_start_5
    monitor-exit v0
    :try_end_5
    .catchall {:try_start_5 .. :try_end_5} :catchall_0

    .line 317
    throw p1

    .line 318
    .line 319
    :cond_3
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 320
    .line 321
    const-string v0, "key URI must start with android-keystore://"

    .line 322
    .line 323
    .line 324
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 325
    throw p1

    .line 326
    :catchall_1
    move-exception p1

    .line 327
    :try_start_6
    monitor-exit v2
    :try_end_6
    .catchall {:try_start_6 .. :try_end_6} :catchall_1

    .line 328
    throw p1

    .line 329
    .line 330
    :cond_4
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 331
    .line 332
    const-string v0, "key URI must start with android-keystore://"

    .line 333
    .line 334
    .line 335
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 336
    throw p1

    .line 337
    .line 338
    :cond_5
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 339
    .line 340
    const-string v0, "need an Android context"

    .line 341
    .line 342
    .line 343
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 344
    throw p1

    .line 345
    :catchall_2
    move-exception p1

    .line 346
    :try_start_7
    monitor-exit v0
    :try_end_7
    .catchall {:try_start_7 .. :try_end_7} :catchall_2

    .line 347
    throw p1

    .line 348
    .line 349
    :cond_6
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 350
    .line 351
    new-instance v0, Ljava/lang/StringBuilder;

    .line 352
    .line 353
    const-string v2, "invalid padding mode, want NoPadding got "

    .line 354
    .line 355
    .line 356
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 357
    .line 358
    .line 359
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getEncryptionPaddings()[Ljava/lang/String;

    .line 360
    move-result-object v1

    .line 361
    .line 362
    .line 363
    invoke-static {v1}, Ljava/util/Arrays;->toString([Ljava/lang/Object;)Ljava/lang/String;

    .line 364
    move-result-object v1

    .line 365
    .line 366
    .line 367
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 368
    .line 369
    .line 370
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 371
    move-result-object v0

    .line 372
    .line 373
    .line 374
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 375
    throw p1

    .line 376
    .line 377
    :cond_7
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 378
    .line 379
    new-instance v0, Ljava/lang/StringBuilder;

    .line 380
    .line 381
    const-string v2, "invalid purposes mode, want PURPOSE_ENCRYPT | PURPOSE_DECRYPT got "

    .line 382
    .line 383
    .line 384
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 385
    .line 386
    .line 387
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getPurposes()I

    .line 388
    move-result v1

    .line 389
    .line 390
    .line 391
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 392
    .line 393
    .line 394
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 395
    move-result-object v0

    .line 396
    .line 397
    .line 398
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 399
    throw p1

    .line 400
    .line 401
    :cond_8
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 402
    .line 403
    new-instance v0, Ljava/lang/StringBuilder;

    .line 404
    .line 405
    const/4 v2, 0x0

    const-string v2, "invalid block mode, want GCM got "

    .line 406
    .line 407
    .line 408
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 409
    .line 410
    .line 411
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getBlockModes()[Ljava/lang/String;

    .line 412
    move-result-object v1

    .line 413
    .line 414
    .line 415
    invoke-static {v1}, Ljava/util/Arrays;->toString([Ljava/lang/Object;)Ljava/lang/String;

    .line 416
    move-result-object v1

    .line 417
    .line 418
    .line 419
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 420
    .line 421
    .line 422
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 423
    move-result-object v0

    .line 424
    .line 425
    .line 426
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 427
    throw p1

    .line 428
    .line 429
    :cond_9
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 430
    .line 431
    new-instance v0, Ljava/lang/StringBuilder;

    .line 432
    .line 433
    const-string v2, "invalid key size, want 256 bits got "

    .line 434
    .line 435
    .line 436
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 437
    .line 438
    .line 439
    invoke-virtual {v1}, Landroid/security/keystore/KeyGenParameterSpec;->getKeySize()I

    .line 440
    move-result v1

    .line 441
    .line 442
    .line 443
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;

    .line 444
    .line 445
    const-string v1, " bits"

    .line 446
    .line 447
    .line 448
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 449
    .line 450
    .line 451
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 452
    move-result-object v0

    .line 453
    .line 454
    .line 455
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 456
    throw p1

    .line 457
    .line 458
    :cond_a
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 459
    .line 460
    const-string v0, "build() called before setKeyGenParameterSpec or setKeyScheme."

    .line 461
    .line 462
    .line 463
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 464
    throw p1

    .line 465
    .line 466
    :cond_b
    new-instance p1, Ljava/lang/IllegalArgumentException;

    .line 467
    .line 468
    new-instance v0, Ljava/lang/StringBuilder;

    .line 469
    .line 470
    const-string v2, "KeyGenParamSpec\'s key alias does not match provided alias (_androidx_security_master_key_ vs "

    .line 471
    .line 472
    .line 473
    invoke-direct {v0, v2}, Ljava/lang/StringBuilder;-><init>(Ljava/lang/String;)V

    .line 474
    .line 475
    .line 476
    invoke-static {v1}, Lh0/c;->a(Landroid/security/keystore/KeyGenParameterSpec;)Ljava/lang/String;

    .line 477
    move-result-object v1

    .line 478
    .line 479
    .line 480
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 481
    .line 482
    .line 483
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 484
    move-result-object v0

    .line 485
    .line 486
    .line 487
    invoke-direct {p1, v0}, Ljava/lang/IllegalArgumentException;-><init>(Ljava/lang/String;)V

    .line 488
    throw p1
.end method

.method public final h()Ljava/util/HashMap;
    .locals 6

    .line 1
    invoke-virtual {p0}, Lk2/a;->c()V

    .line 2
    .line 3
    .line 4
    iget-object v0, p0, Lk2/a;->f:Landroid/content/SharedPreferences;

    .line 5
    .line 6
    invoke-interface {v0}, Landroid/content/SharedPreferences;->getAll()Ljava/util/Map;

    .line 7
    .line 8
    .line 9
    move-result-object v0

    .line 10
    new-instance v1, Ljava/util/HashMap;

    .line 11
    .line 12
    invoke-direct {v1}, Ljava/util/HashMap;-><init>()V

    .line 13
    .line 14
    .line 15
    invoke-interface {v0}, Ljava/util/Map;->entrySet()Ljava/util/Set;

    .line 16
    .line 17
    .line 18
    move-result-object v0

    .line 19
    invoke-interface {v0}, Ljava/util/Set;->iterator()Ljava/util/Iterator;

    .line 20
    .line 21
    .line 22
    move-result-object v0

    .line 23
    :cond_0
    :goto_0
    invoke-interface {v0}, Ljava/util/Iterator;->hasNext()Z

    .line 24
    .line 25
    .line 26
    move-result v2

    .line 27
    if-eqz v2, :cond_2

    .line 28
    .line 29
    invoke-interface {v0}, Ljava/util/Iterator;->next()Ljava/lang/Object;

    .line 30
    .line 31
    .line 32
    move-result-object v2

    .line 33
    check-cast v2, Ljava/util/Map$Entry;

    .line 34
    .line 35
    invoke-interface {v2}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    .line 36
    .line 37
    .line 38
    move-result-object v3

    .line 39
    check-cast v3, Ljava/lang/String;

    .line 40
    .line 41
    iget-object v4, p0, Lk2/a;->c:Ljava/lang/String;

    .line 42
    .line 43
    invoke-virtual {v3, v4}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z

    .line 44
    .line 45
    .line 46
    move-result v3

    .line 47
    if-eqz v3, :cond_0

    .line 48
    .line 49
    invoke-interface {v2}, Ljava/util/Map$Entry;->getKey()Ljava/lang/Object;

    .line 50
    .line 51
    .line 52
    move-result-object v3

    .line 53
    check-cast v3, Ljava/lang/String;

    .line 54
    .line 55
    new-instance v4, Ljava/lang/StringBuilder;

    .line 56
    .line 57
    invoke-direct {v4}, Ljava/lang/StringBuilder;-><init>()V

    .line 58
    .line 59
    .line 60
    iget-object v5, p0, Lk2/a;->c:Ljava/lang/String;

    .line 61
    .line 62
    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    .line 63
    .line 64
    .line 65
    const/16 v5, 0x5f

    .line 66
    .line 67
    invoke-virtual {v4, v5}, Ljava/lang/StringBuilder;->append(C)Ljava/lang/StringBuilder;

    .line 68
    .line 69
    .line 70
    invoke-virtual {v4}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    .line 71
    .line 72
    .line 73
    move-result-object v4

    .line 74
    const-string v5, ""

    .line 75
    .line 76
    invoke-virtual {v3, v4, v5}, Ljava/lang/String;->replaceFirst(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    .line 77
    .line 78
    .line 79
    move-result-object v3

    .line 80
    invoke-virtual {p0}, Lk2/a;->e()Z

    .line 81
    .line 82
    .line 83
    move-result v4

    .line 84
    if-eqz v4, :cond_1

    .line 85
    .line 86
    invoke-interface {v2}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    .line 87
    .line 88
    .line 89
    move-result-object v2

    .line 90
    check-cast v2, Ljava/lang/String;

    .line 91
    .line 92
    invoke-virtual {v1, v3, v2}, Ljava/util/HashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 93
    .line 94
    .line 95
    goto :goto_0

    .line 96
    :cond_1
    invoke-interface {v2}, Ljava/util/Map$Entry;->getValue()Ljava/lang/Object;

    .line 97
    .line 98
    .line 99
    move-result-object v2

    .line 100
    check-cast v2, Ljava/lang/String;

    .line 101
    .line 102
    invoke-virtual {p0, v2}, Lk2/a;->b(Ljava/lang/String;)Ljava/lang/String;

    .line 103
    .line 104
    .line 105
    move-result-object v2

    .line 106
    invoke-virtual {v1, v3, v2}, Ljava/util/HashMap;->put(Ljava/lang/Object;Ljava/lang/Object;)Ljava/lang/Object;

    .line 107
    .line 108
    .line 109
    goto :goto_0

    .line 110
    :cond_2
    return-object v1
.end method

.method public final i(Ljava/lang/String;Ljava/lang/String;)V
    .locals 3

    .line 1
    invoke-virtual {p0}, Lk2/a;->c()V

    .line 2
    .line 3
    .line 4
    iget-object v0, p0, Lk2/a;->f:Landroid/content/SharedPreferences;

    .line 5
    .line 6
    invoke-interface {v0}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;

    .line 7
    .line 8
    .line 9
    move-result-object v0

    .line 10
    invoke-virtual {p0}, Lk2/a;->e()Z

    .line 11
    .line 12
    .line 13
    move-result v1

    .line 14
    if-eqz v1, :cond_0

    .line 15
    .line 16
    invoke-interface {v0, p1, p2}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 17
    .line 18
    .line 19
    goto :goto_0

    .line 20
    :cond_0
    iget-object v1, p0, Lk2/a;->g:LB1/a;

    .line 21
    .line 22
    iget-object v2, p0, Lk2/a;->a:Ljava/nio/charset/Charset;

    .line 23
    .line 24
    invoke-virtual {p2, v2}, Ljava/lang/String;->getBytes(Ljava/nio/charset/Charset;)[B

    .line 25
    .line 26
    .line 27
    move-result-object p2

    .line 28
    invoke-virtual {v1, p2}, LB1/a;->D([B)[B

    .line 29
    .line 30
    .line 31
    move-result-object p2

    .line 32
    const/4 v1, 0x0

    .line 33
    invoke-static {p2, v1}, Landroid/util/Base64;->encodeToString([BI)Ljava/lang/String;

    .line 34
    .line 35
    .line 36
    move-result-object p2

    .line 37
    invoke-interface {v0, p1, p2}, Landroid/content/SharedPreferences$Editor;->putString(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;

    .line 38
    .line 39
    .line 40
    :goto_0
    invoke-interface {v0}, Landroid/content/SharedPreferences$Editor;->apply()V

    .line 41
    .line 42
    .line 43
    return-void
.end method
