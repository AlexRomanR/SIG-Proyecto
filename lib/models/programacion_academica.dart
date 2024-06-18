import 'dart:convert';

List<ProgramacionAcademica> programacionAcademicaFromMap(String str) => List<ProgramacionAcademica>.from(json.decode(str).map((x) => ProgramacionAcademica.fromMap(x)));

String programacionAcademicaToMap(List<ProgramacionAcademica> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ProgramacionAcademica {
    int id;
    Docente docente;
    Materia materia;
    String horarioInicio;
    String horarioFin;
    String grupo;
    String dia;
    Carrera carrera;
    Aula aula;
    Modulo modulo;
    Facultad facultad;

    ProgramacionAcademica({
        required this.id,
        required this.docente,
        required this.materia,
        required this.horarioInicio,
        required this.horarioFin,
        required this.grupo,
        required this.dia,
        required this.carrera,
        required this.aula,
        required this.modulo,
        required this.facultad,
    });

    factory ProgramacionAcademica.fromMap(Map<String, dynamic> json) => ProgramacionAcademica(
        id: json["id"],
        docente: Docente.fromMap(json["docente"]),
        materia: Materia.fromMap(json["materia"]),
        horarioInicio: json["horario_inicio"],
        horarioFin: json["horario_fin"],
        grupo: json["grupo"],
        dia: json["dia"],
        carrera: Carrera.fromMap(json["carrera"]),
        aula: Aula.fromMap(json["aula"]),
        modulo: Modulo.fromMap(json["modulo"]),
        facultad: Facultad.fromMap(json["facultad"]),
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "docente": docente.toMap(),
        "materia": materia.toMap(),
        "horario_inicio": horarioInicio,
        "horario_fin": horarioFin,
        "grupo": grupo,
        "dia": dia,
        "carrera": carrera.toMap(),
        "aula": aula.toMap(),
        "modulo": modulo.toMap(),
        "facultad": facultad.toMap(),
    };
}

class Aula {
    int id;
    int numero;
    int piso;
    int capacidad;
    String descripcion;
    int moduloId;

    Aula({
        required this.id,
        required this.numero,
        required this.piso,
        required this.capacidad,
        required this.descripcion,
        required this.moduloId,
    });

    factory Aula.fromMap(Map<String, dynamic> json) => Aula(
        id: json["id"],
        numero: json["numero"],
        piso: json["piso"],
        capacidad: json["capacidad"],
        descripcion: json["descripcion"],
        moduloId: json["modulo_id"],
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "numero": numero,
        "piso": piso,
        "capacidad": capacidad,
        "descripcion": descripcion,
        "modulo_id": moduloId,
    };
}

class Carrera {
    int id;
    String codigo;
    String nombre;
    List<dynamic> materias;

    Carrera({
        required this.id,
        required this.codigo,
        required this.nombre,
        required this.materias,
    });

    factory Carrera.fromMap(Map<String, dynamic> json) => Carrera(
        id: json["id"],
        codigo: json["codigo"],
        nombre: json["nombre"],
        materias: List<dynamic>.from(json["materias"].map((x) => x)),
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "codigo": codigo,
        "nombre": nombre,
        "materias": List<dynamic>.from(materias.map((x) => x)),
    };
}

class Docente {
    int id;
    String email;
    String name;
    String password;
    String role;
    List<dynamic> docenteMaterias;
    bool enabled;
    List<Authority> authorities;
    String username;
    bool accountNonExpired;
    bool credentialsNonExpired;
    bool accountNonLocked;

    Docente({
        required this.id,
        required this.email,
        required this.name,
        required this.password,
        required this.role,
        required this.docenteMaterias,
        required this.enabled,
        required this.authorities,
        required this.username,
        required this.accountNonExpired,
        required this.credentialsNonExpired,
        required this.accountNonLocked,
    });

    factory Docente.fromMap(Map<String, dynamic> json) => Docente(
        id: json["id"],
        email: json["email"],
        name: json["name"],
        password: json["password"],
        role: json["role"],
        docenteMaterias: List<dynamic>.from(json["docenteMaterias"].map((x) => x)),
        enabled: json["enabled"],
        authorities: List<Authority>.from(json["authorities"].map((x) => Authority.fromMap(x))),
        username: json["username"],
        accountNonExpired: json["accountNonExpired"],
        credentialsNonExpired: json["credentialsNonExpired"],
        accountNonLocked: json["accountNonLocked"],
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "email": email,
        "name": name,
        "password": password,
        "role": role,
        "docenteMaterias": List<dynamic>.from(docenteMaterias.map((x) => x)),
        "enabled": enabled,
        "authorities": List<dynamic>.from(authorities.map((x) => x.toMap())),
        "username": username,
        "accountNonExpired": accountNonExpired,
        "credentialsNonExpired": credentialsNonExpired,
        "accountNonLocked": accountNonLocked,
    };
}

class Authority {
    String authority;

    Authority({
        required this.authority,
    });

    factory Authority.fromMap(Map<String, dynamic> json) => Authority(
        authority: json["authority"],
    );

    Map<String, dynamic> toMap() => {
        "authority": authority,
    };
}

class Facultad {
    int id;
    String nombre;
    String descripcion;
    List<Modulo> modulos;

    Facultad({
        required this.id,
        required this.nombre,
        required this.descripcion,
        required this.modulos,
    });

    factory Facultad.fromMap(Map<String, dynamic> json) => Facultad(
        id: json["id"],
        nombre: json["nombre"],
        descripcion: json["descripcion"],
        modulos: List<Modulo>.from(json["modulos"].map((x) => Modulo.fromMap(x))),
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "nombre": nombre,
        "descripcion": descripcion,
        "modulos": List<dynamic>.from(modulos.map((x) => x.toMap())),
    };
}

class Modulo {
    int id;
    int numero;
    String descripcion;
    String ubicacion;
    List<Aula> aulas;
    int facultadId;

    Modulo({
        required this.id,
        required this.numero,
        required this.descripcion,
        required this.ubicacion,
        required this.aulas,
        required this.facultadId,
    });

    factory Modulo.fromMap(Map<String, dynamic> json) => Modulo(
        id: json["id"],
        numero: json["numero"],
        descripcion: json["descripcion"],
        ubicacion: json["ubicacion"],
        aulas: List<Aula>.from(json["aulas"].map((x) => Aula.fromMap(x))),
        facultadId: json["facultad_id"],
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "numero": numero,
        "descripcion": descripcion,
        "ubicacion": ubicacion,
        "aulas": List<dynamic>.from(aulas.map((x) => x.toMap())),
        "facultad_id": facultadId,
    };
}

class Materia {
    int id;
    String sigla;
    String nombre;
    List<dynamic> carreras;

    Materia({
        required this.id,
        required this.sigla,
        required this.nombre,
        required this.carreras,
    });

    factory Materia.fromMap(Map<String, dynamic> json) => Materia(
        id: json["id"],
        sigla: json["sigla"],
        nombre: json["nombre"],
        carreras: List<dynamic>.from(json["carreras"].map((x) => x)),
    );

    Map<String, dynamic> toMap() => {
        "id": id,
        "sigla": sigla,
        "nombre": nombre,
        "carreras": List<dynamic>.from(carreras.map((x) => x)),
    };
}
