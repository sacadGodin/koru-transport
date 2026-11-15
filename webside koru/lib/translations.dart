import 'lang.dart';

// French, Arabic and Russian texts of the site.
// Each English text from context.t('English', 'Türkçe') is looked up here.
// A text that is missing here is shown in English.
// "{}" stands for a value filled in by the code (a name, a number, ...).
// TODO: have a native speaker check these translations before going live.
const translations = <String, Map<Lang, String>>{
  // Transport types, needs and booking stages.
  "Ambulance": {
    Lang.fr: "Ambulance",
    Lang.ar: "سيارة إسعاف",
    Lang.ru: "Скорая помощь"
  },
  "Wheelchair vehicle": {
    Lang.fr: "Véhicule pour fauteuil roulant",
    Lang.ar: "مركبة للكراسي المتحركة",
    Lang.ru: "Автомобиль для инвалидной коляски"
  },
  "Standard car": {
    Lang.fr: "Voiture standard",
    Lang.ar: "سيارة عادية",
    Lang.ru: "Обычный автомобиль"
  },
  "Airport transfer": {
    Lang.fr: "Transfert aéroport",
    Lang.ar: "نقل من وإلى المطار",
    Lang.ru: "Трансфер из аэропорта"
  },
  "Wheelchair": {
    Lang.fr: "Fauteuil roulant",
    Lang.ar: "كرسي متحرك",
    Lang.ru: "Инвалидная коляска"
  },
  "Stretcher": {Lang.fr: "Brancard", Lang.ar: "نقالة", Lang.ru: "Носилки"},
  "Oxygen": {Lang.fr: "Oxygène", Lang.ar: "أكسجين", Lang.ru: "Кислород"},
  "Companion": {
    Lang.fr: "Accompagnant",
    Lang.ar: "مرافق",
    Lang.ru: "Сопровождающий"
  },
  "New requests": {
    Lang.fr: "Nouvelles demandes",
    Lang.ar: "طلبات جديدة",
    Lang.ru: "Новые заявки"
  },
  "Confirmed": {Lang.fr: "Confirmée", Lang.ar: "مؤكد", Lang.ru: "Подтверждено"},
  "Reserved": {Lang.fr: "Réservée", Lang.ar: "محجوز", Lang.ru: "Забронировано"},
  "Arranged": {
    Lang.fr: "Organisée",
    Lang.ar: "تم الترتيب",
    Lang.ru: "Организовано"
  },
  "Next: confirm": {
    Lang.fr: "Étape suivante : confirmer",
    Lang.ar: "التالي: التأكيد",
    Lang.ru: "Далее: подтвердить"
  },
  "Next: reserve": {
    Lang.fr: "Étape suivante : réserver",
    Lang.ar: "التالي: الحجز",
    Lang.ru: "Далее: забронировать"
  },
  "Next: assign driver": {
    Lang.fr: "Étape suivante : attribuer un chauffeur",
    Lang.ar: "التالي: تعيين سائق",
    Lang.ru: "Далее: назначить водителя"
  },
  "Ready to go": {
    Lang.fr: "Prêt à partir",
    Lang.ar: "جاهز للانطلاق",
    Lang.ru: "Готово к поездке"
  },

  // Feedback page.
  "How was your ride?": {
    Lang.fr: "Comment s'est passé votre trajet ?",
    Lang.ar: "كيف كانت رحلتك؟",
    Lang.ru: "Как прошла ваша поездка?"
  },
  "Your comment helps us look after the next patient better. It takes one minute.":
      {
    Lang.fr:
        "Votre avis nous aide à mieux prendre soin du prochain patient. Cela prend une minute.",
    Lang.ar:
        "يساعدنا تعليقك على رعاية المريض التالي بشكل أفضل. لن يستغرق سوى دقيقة.",
    Lang.ru:
        "Ваш отзыв помогает нам лучше заботиться о следующем пациенте. Это займёт одну минуту."
  },
  "Your rating": {
    Lang.fr: "Votre note",
    Lang.ar: "تقييمك",
    Lang.ru: "Ваша оценка"
  },
  "Choose 1 to 5 stars": {
    Lang.fr: "Choisissez de 1 à 5 étoiles",
    Lang.ar: "اختر من 1 إلى 5 نجوم",
    Lang.ru: "Выберите от 1 до 5 звёзд"
  },
  "Service you used": {
    Lang.fr: "Service utilisé",
    Lang.ar: "الخدمة التي استخدمتها",
    Lang.ru: "Услуга, которой вы воспользовались"
  },
  "Your comment": {
    Lang.fr: "Votre commentaire",
    Lang.ar: "تعليقك",
    Lang.ru: "Ваш отзыв"
  },
  "What went well? What could we do better?": {
    Lang.fr: "Qu'est-ce qui s'est bien passé ? Que pourrions-nous améliorer ?",
    Lang.ar: "ما الذي كان جيدًا؟ وما الذي يمكننا تحسينه؟",
    Lang.ru: "Что понравилось? Что мы можем сделать лучше?"
  },
  "Required": {
    Lang.fr: "Obligatoire",
    Lang.ar: "حقل مطلوب",
    Lang.ru: "Обязательное поле"
  },
  "Your name (optional)": {
    Lang.fr: "Votre nom (facultatif)",
    Lang.ar: "اسمك (اختياري)",
    Lang.ru: "Ваше имя (необязательно)"
  },
  "Booking reference (optional)": {
    Lang.fr: "Numéro de réservation (facultatif)",
    Lang.ar: "رقم الحجز (اختياري)",
    Lang.ru: "Номер бронирования (необязательно)"
  },
  "Our team reads every comment. We may show it on our website with your first name only. Please don't write medical details.":
      {
    Lang.fr:
        "Notre équipe lit chaque commentaire. Nous pouvons l'afficher sur notre site avec votre prénom uniquement. Merci de ne pas indiquer d'informations médicales.",
    Lang.ar:
        "يقرأ فريقنا كل تعليق. قد نعرضه على موقعنا باسمك الأول فقط. يرجى عدم كتابة معلومات طبية.",
    Lang.ru:
        "Наша команда читает каждый отзыв. Мы можем показать его на сайте только с вашим именем. Пожалуйста, не указывайте медицинские данные."
  },
  "Send feedback": {
    Lang.fr: "Envoyer l'avis",
    Lang.ar: "إرسال التعليق",
    Lang.ru: "Отправить отзыв"
  },
  "Thank you!": {Lang.fr: "Merci !", Lang.ar: "شكرًا لك!", Lang.ru: "Спасибо!"},
  "We received your feedback and our team will read it.": {
    Lang.fr: "Nous avons bien reçu votre avis et notre équipe va le lire.",
    Lang.ar: "لقد استلمنا تعليقك وسيقرؤه فريقنا.",
    Lang.ru: "Мы получили ваш отзыв, наша команда его прочитает."
  },
  "Back to homepage": {
    Lang.fr: "Retour à l'accueil",
    Lang.ar: "العودة إلى الصفحة الرئيسية",
    Lang.ru: "На главную"
  },
  "Leave another comment": {
    Lang.fr: "Laisser un autre commentaire",
    Lang.ar: "اترك تعليقًا آخر",
    Lang.ru: "Оставить ещё отзыв"
  },

  // Staff login.
  "Staff portal": {
    Lang.fr: "Espace personnel",
    Lang.ar: "بوابة الموظفين",
    Lang.ru: "Портал сотрудников"
  },
  "For Koru Hospital transport coordinators only. Manage requests, reservations and dispatch.":
      {
    Lang.fr:
        "Réservé aux coordinateurs transport de l'hôpital Koru. Gérez les demandes, les réservations et les départs.",
    Lang.ar:
        "مخصص لمنسقي النقل في مستشفى كورو فقط. إدارة الطلبات والحجوزات وإرسال المركبات.",
    Lang.ru:
        "Только для координаторов транспорта больницы Koru. Управление заявками, бронированиями и выездами."
  },
  "Staff sign in": {
    Lang.fr: "Connexion du personnel",
    Lang.ar: "تسجيل دخول الموظفين",
    Lang.ru: "Вход для сотрудников"
  },
  "Use your hospital account.": {
    Lang.fr: "Utilisez votre compte de l'hôpital.",
    Lang.ar: "استخدم حسابك في المستشفى.",
    Lang.ru: "Используйте учётную запись больницы."
  },
  "Email": {
    Lang.fr: "E-mail",
    Lang.ar: "البريد الإلكتروني",
    Lang.ru: "Эл. почта"
  },
  "Password": {
    Lang.fr: "Mot de passe",
    Lang.ar: "كلمة المرور",
    Lang.ru: "Пароль"
  },
  "Show password": {
    Lang.fr: "Afficher le mot de passe",
    Lang.ar: "إظهار كلمة المرور",
    Lang.ru: "Показать пароль"
  },
  "Hide password": {
    Lang.fr: "Masquer le mot de passe",
    Lang.ar: "إخفاء كلمة المرور",
    Lang.ru: "Скрыть пароль"
  },
  "Forgot password?": {
    Lang.fr: "Mot de passe oublié ?",
    Lang.ar: "نسيت كلمة المرور؟",
    Lang.ru: "Забыли пароль?"
  },
  "Sign in": {
    Lang.fr: "Se connecter",
    Lang.ar: "تسجيل الدخول",
    Lang.ru: "Войти"
  },
  // Sign-in page (first page of the site).
  "Staff": {Lang.fr: "Personnel", Lang.ar: "موظف", Lang.ru: "Сотрудник"},
  "Admin": {
    Lang.fr: "Administrateur",
    Lang.ar: "مسؤول",
    Lang.ru: "Администратор"
  },
  "Driver": {Lang.fr: "Chauffeur", Lang.ar: "سائق", Lang.ru: "Водитель"},
  "Welcome back": {
    Lang.fr: "Bon retour",
    Lang.ar: "مرحبًا بعودتك",
    Lang.ru: "С возвращением"
  },
  "Sign in to the Koru Transport portal.": {
    Lang.fr: "Connectez-vous au portail Koru Transport.",
    Lang.ar: "سجّل الدخول إلى بوابة كورو للنقل.",
    Lang.ru: "Войдите в портал Koru Transport."
  },
  "I am signing in as": {
    Lang.fr: "Je me connecte en tant que",
    Lang.ar: "أسجّل الدخول بصفتي",
    Lang.ru: "Я вхожу как"
  },
  "Book rides and see transport information.": {
    Lang.fr: "Réservez des trajets et consultez les informations de transport.",
    Lang.ar: "احجز الرحلات واطّلع على معلومات النقل.",
    Lang.ru: "Заказывайте поездки и смотрите информацию о транспорте."
  },
  "Manage bookings, drivers, the schedule and all settings.": {
    Lang.fr:
        "Gérez les réservations, les chauffeurs, le planning et tous les réglages.",
    Lang.ar: "أدر الحجوزات والسائقين والجدول وجميع الإعدادات.",
    Lang.ru:
        "Управляйте бронированиями, водителями, расписанием и всеми настройками."
  },
  "Use the account your coordinator gave you.": {
    Lang.fr: "Utilisez le compte fourni par votre coordinateur.",
    Lang.ar: "استخدم الحساب الذي أعطاك إياه المنسق.",
    Lang.ru: "Используйте учётную запись, выданную координатором."
  },
  "This account is not a staff account.": {
    Lang.fr: "Ce compte n'est pas un compte du personnel.",
    Lang.ar: "هذا الحساب ليس حساب موظف.",
    Lang.ru: "Эта учётная запись не принадлежит сотруднику."
  },
  "Secure sign-in for authorised personnel": {
    Lang.fr: "Connexion sécurisée réservée au personnel autorisé",
    Lang.ar: "تسجيل دخول آمن للموظفين المخوّلين",
    Lang.ru: "Защищённый вход для уполномоченного персонала"
  },
  "KORU HOSPITAL · STAFF PORTAL": {
    Lang.fr: "HÔPITAL KORU · ESPACE PERSONNEL",
    Lang.ar: "مستشفى كورو · بوابة الموظفين",
    Lang.ru: "БОЛЬНИЦА KORU · ПОРТАЛ СОТРУДНИКОВ"
  },
  "Moving People,\nConnecting Care.": {
    Lang.fr: "Transporter les personnes,\nrelier les soins.",
    Lang.ar: "ننقل الناس،\nونصل الرعاية.",
    Lang.ru: "Перевозим людей,\nсоединяем заботу."
  },
  "The Koru Transport portal brings coordinators, administrators and drivers together to move every patient safely and on time.":
      {
    Lang.fr:
        "Le portail Koru Transport réunit coordinateurs, administrateurs et chauffeurs pour transporter chaque patient en sécurité et à l'heure.",
    Lang.ar:
        "تجمع بوابة كورو للنقل المنسقين والمسؤولين والسائقين لنقل كل مريض بأمان وفي الوقت المحدد.",
    Lang.ru:
        "Портал Koru Transport объединяет координаторов, администраторов и водителей, чтобы каждый пациент был доставлен безопасно и вовремя."
  },
  "Live dispatch and trip tracking": {
    Lang.fr: "Répartition et suivi des trajets en direct",
    Lang.ar: "إرسال مباشر وتتبّع للرحلات",
    Lang.ru: "Диспетчеризация и отслеживание поездок в реальном времени"
  },
  "Bookings and 24-hour schedule": {
    Lang.fr: "Réservations et planning 24 h/24",
    Lang.ar: "الحجوزات وجدول على مدار 24 ساعة",
    Lang.ru: "Бронирования и круглосуточное расписание"
  },
  "Role-based secure access": {
    Lang.fr: "Accès sécurisé selon le rôle",
    Lang.ar: "وصول آمن حسب الدور",
    Lang.ru: "Защищённый доступ по ролям"
  },
  "Admin dashboard": {
    Lang.fr: "Tableau de bord administrateur",
    Lang.ar: "لوحة تحكم المسؤول",
    Lang.ru: "Панель администратора"
  },
  "Driver dashboard": {
    Lang.fr: "Tableau de bord chauffeur",
    Lang.ar: "لوحة تحكم السائق",
    Lang.ru: "Панель водителя"
  },
  "Account": {Lang.fr: "Compte", Lang.ar: "الحساب", Lang.ru: "Аккаунт"},
  "Accounts": {Lang.fr: "Comptes", Lang.ar: "الحسابات", Lang.ru: "Аккаунты"},
  "Add account": {
    Lang.fr: "Ajouter un compte",
    Lang.ar: "إضافة حساب",
    Lang.ru: "Добавить аккаунт"
  },
  "Edit account": {
    Lang.fr: "Modifier le compte",
    Lang.ar: "تعديل الحساب",
    Lang.ru: "Изменить аккаунт"
  },
  "Remove account": {
    Lang.fr: "Supprimer le compte",
    Lang.ar: "إزالة الحساب",
    Lang.ru: "Удалить аккаунт"
  },
  "Remove": {Lang.fr: "Supprimer", Lang.ar: "إزالة", Lang.ru: "Удалить"},
  "No accounts yet.": {
    Lang.fr: "Aucun compte pour l'instant.",
    Lang.ar: "لا توجد حسابات بعد.",
    Lang.ru: "Аккаунтов пока нет."
  },
  "(no name)": {
    Lang.fr: "(sans nom)",
    Lang.ar: "(بدون اسم)",
    Lang.ru: "(без имени)"
  },
  "(you)": {Lang.fr: "(vous)", Lang.ar: "(أنت)", Lang.ru: "(вы)"},
  "Access": {Lang.fr: "Accès", Lang.ar: "الصلاحية", Lang.ru: "Доступ"},
  "Manages everything in this dashboard.": {
    Lang.fr: "Gère tout dans ce tableau de bord.",
    Lang.ar: "يدير كل شيء في لوحة التحكم هذه.",
    Lang.ru: "Управляет всем на этой панели."
  },
  "Uses the main site only: books rides and sees information.": {
    Lang.fr:
        "Utilise uniquement le site principal : réserve des trajets et consulte les informations.",
    Lang.ar: "يستخدم الموقع الرئيسي فقط: يحجز الرحلات ويطّلع على المعلومات.",
    Lang.ru:
        "Пользуется только основным сайтом: заказывает поездки и смотрит информацию."
  },
  "Not allowed. Only admins can manage accounts.": {
    Lang.fr: "Non autorisé. Seuls les administrateurs gèrent les comptes.",
    Lang.ar: "غير مسموح. يمكن للمسؤولين فقط إدارة الحسابات.",
    Lang.ru: "Нет доступа. Аккаунтами управляют только администраторы."
  },
  "Could not save the account. Please try again.": {
    Lang.fr: "Impossible d'enregistrer le compte. Veuillez réessayer.",
    Lang.ar: "تعذّر حفظ الحساب. يرجى المحاولة مرة أخرى.",
    Lang.ru: "Не удалось сохранить аккаунт. Попробуйте ещё раз."
  },
  "Could not remove the account.": {
    Lang.fr: "Impossible de supprimer le compte.",
    Lang.ar: "تعذّرت إزالة الحساب.",
    Lang.ru: "Не удалось удалить аккаунт."
  },
  "Staff sign in with the Staff tab and use the main site: book rides and see information. Admins sign in with the Admin tab and manage everything here. Drivers are in the Drivers section.":
      {
    Lang.fr:
        "Le personnel se connecte avec l'onglet Personnel et utilise le site principal : réserver des trajets et consulter les informations. Les administrateurs se connectent avec l'onglet Administrateur et gèrent tout ici. Les chauffeurs sont dans la section Chauffeurs.",
    Lang.ar:
        "يسجّل الموظفون الدخول من تبويب الموظف ويستخدمون الموقع الرئيسي: حجز الرحلات والاطلاع على المعلومات. يسجّل المسؤولون الدخول من تبويب المسؤول ويديرون كل شيء هنا. السائقون في قسم السائقين.",
    Lang.ru:
        "Сотрудники входят через вкладку «Сотрудник» и пользуются основным сайтом: заказывают поездки и смотрят информацию. Администраторы входят через вкладку «Администратор» и управляют всем здесь. Водители — в разделе «Водители»."
  },
  "{} will no longer be able to sign in. This cannot be undone.": {
    Lang.fr: "{} ne pourra plus se connecter. Cette action est irréversible.",
    Lang.ar: "لن يتمكن {} من تسجيل الدخول بعد الآن. لا يمكن التراجع عن ذلك.",
    Lang.ru: "{} больше не сможет войти. Это действие нельзя отменить."
  },
  "Back to website": {
    Lang.fr: "Retour au site",
    Lang.ar: "العودة إلى الموقع",
    Lang.ru: "Вернуться на сайт"
  },

  // Homepage: hero and booking bar.
  "Coordinators available 24/7": {
    Lang.fr: "Coordinateurs disponibles 24 h/24, 7 j/7",
    Lang.ar: "المنسقون متاحون على مدار الساعة",
    Lang.ru: "Координаторы на связи 24/7"
  },
  "Ambulance transfers, accessible vehicles and airport pickups for Koru Hospital patients and visitors.":
      {
    Lang.fr:
        "Transferts en ambulance, véhicules adaptés et accueil à l'aéroport pour les patients et visiteurs de l'hôpital Koru.",
    Lang.ar:
        "نقل بالإسعاف، ومركبات مجهزة لذوي الإعاقة، واستقبال من المطار لمرضى وزوار مستشفى كورو.",
    Lang.ru:
        "Перевозка на скорой, автомобили для людей с ограниченной подвижностью и встреча в аэропорту для пациентов и посетителей больницы Koru."
  },
  "Service": {Lang.fr: "Service", Lang.ar: "الخدمة", Lang.ru: "Услуга"},
  "From": {Lang.fr: "Départ", Lang.ar: "من", Lang.ru: "Откуда"},
  "Pickup address": {
    Lang.fr: "Adresse de prise en charge",
    Lang.ar: "عنوان الانطلاق",
    Lang.ru: "Адрес посадки"
  },
  "To": {Lang.fr: "Arrivée", Lang.ar: "إلى", Lang.ru: "Куда"},
  "Date": {Lang.fr: "Date", Lang.ar: "التاريخ", Lang.ru: "Дата"},
  "Select": {Lang.fr: "Choisir", Lang.ar: "اختر", Lang.ru: "Выбрать"},
  "Book ride": {Lang.fr: "Réserver", Lang.ar: "احجز رحلة", Lang.ru: "Заказать"},

  // Homepage: services.
  "Airport ⇄ Hotel or Hospital": {
    Lang.fr: "Aéroport ⇄ Hôtel ou hôpital",
    Lang.ar: "المطار ⇄ الفندق أو المستشفى",
    Lang.ru: "Аэропорт ⇄ Отель или больница"
  },
  "We meet you at arrivals and take you to your hotel or straight to your appointment. The same on your way home.":
      {
    Lang.fr:
        "Nous vous accueillons aux arrivées et vous conduisons à votre hôtel ou directement à votre rendez-vous. De même pour le retour.",
    Lang.ar:
        "نستقبلك في صالة الوصول ونوصلك إلى فندقك أو مباشرة إلى موعدك. وكذلك في طريق العودة.",
    Lang.ru:
        "Встретим вас в зоне прилёта и отвезём в отель или сразу на приём. Так же и на обратном пути."
  },
  "Driver waiting with your name sign": {
    Lang.fr: "Chauffeur avec une pancarte à votre nom",
    Lang.ar: "سائق ينتظرك بلافتة تحمل اسمك",
    Lang.ru: "Водитель встречает с табличкой с вашим именем"
  },
  "Flight tracking: on time even if your flight is late": {
    Lang.fr: "Suivi du vol : à l'heure même si votre vol est en retard",
    Lang.ar: "متابعة الرحلة: في الموعد حتى لو تأخرت رحلتك",
    Lang.ru: "Отслеживание рейса: вовремя, даже если рейс задерживается"
  },
  "Help with your luggage": {
    Lang.fr: "Aide pour vos bagages",
    Lang.ar: "مساعدة في حمل الأمتعة",
    Lang.ru: "Помощь с багажом"
  },
  "Return trip timed to your flight": {
    Lang.fr: "Retour organisé selon votre vol",
    Lang.ar: "رحلة عودة حسب موعد رحلتك",
    Lang.ru: "Обратная поездка ко времени вашего рейса"
  },
  "Hotel–hospital rides": {
    Lang.fr: "Trajets hôtel–hôpital",
    Lang.ar: "التنقل بين الفندق والمستشفى",
    Lang.ru: "Поездки отель–больница"
  },
  "Hotel ⇄ Hospital": {
    Lang.fr: "Hôtel ⇄ Hôpital",
    Lang.ar: "الفندق ⇄ المستشفى",
    Lang.ru: "Отель ⇄ Больница"
  },
  "Rides to every check-up, test, surgery and follow-up visit during your treatment.":
      {
    Lang.fr:
        "Trajets pour chaque contrôle, examen, opération et visite de suivi pendant votre traitement.",
    Lang.ar: "رحلات إلى كل فحص وتحليل وعملية وزيارة متابعة خلال فترة علاجك.",
    Lang.ru:
        "Поездки на каждый осмотр, анализ, операцию и контрольный визит во время лечения."
  },
  "Planned around your appointment times": {
    Lang.fr: "Planifié selon vos rendez-vous",
    Lang.ar: "مخطط حسب مواعيدك",
    Lang.ru: "По времени ваших приёмов"
  },
  "Driver waits and takes you back": {
    Lang.fr: "Le chauffeur attend et vous ramène",
    Lang.ar: "السائق ينتظرك ويعيدك",
    Lang.ru: "Водитель ждёт и отвозит обратно"
  },
  "A family member can ride with you": {
    Lang.fr: "Un proche peut vous accompagner",
    Lang.ar: "يمكن لأحد أفراد العائلة مرافقتك",
    Lang.ru: "С вами может поехать родственник"
  },
  "Gentle ride back after discharge": {
    Lang.fr: "Retour en douceur après la sortie",
    Lang.ar: "عودة مريحة بعد الخروج من المستشفى",
    Lang.ru: "Бережная поездка домой после выписки"
  },
  "Medical transfer": {
    Lang.fr: "Transfert médical",
    Lang.ar: "نقل طبي",
    Lang.ru: "Медицинская перевозка"
  },
  "For patients who need care on the way": {
    Lang.fr: "Pour les patients ayant besoin de soins pendant le trajet",
    Lang.ar: "للمرضى الذين يحتاجون إلى رعاية أثناء الطريق",
    Lang.ru: "Для пациентов, которым нужен уход в пути"
  },
  "Vehicles and staff for patients who cannot travel in a normal car, before or after treatment.":
      {
    Lang.fr:
        "Véhicules et personnel pour les patients qui ne peuvent pas voyager en voiture normale, avant ou après le traitement.",
    Lang.ar:
        "مركبات وطاقم للمرضى الذين لا يستطيعون السفر في سيارة عادية، قبل العلاج أو بعده.",
    Lang.ru:
        "Транспорт и персонал для пациентов, которые не могут ехать в обычной машине, до или после лечения."
  },
  "Wheelchair vehicle with ramp": {
    Lang.fr: "Véhicule pour fauteuil avec rampe",
    Lang.ar: "مركبة للكراسي المتحركة مع منحدر",
    Lang.ru: "Автомобиль для коляски с пандусом"
  },
  "Stretcher transfer": {
    Lang.fr: "Transfert sur brancard",
    Lang.ar: "نقل على نقالة",
    Lang.ru: "Перевозка на носилках"
  },
  "Ambulance with a paramedic": {
    Lang.fr: "Ambulance avec un secouriste",
    Lang.ar: "سيارة إسعاف مع مسعف",
    Lang.ru: "Скорая с фельдшером"
  },
  "Oxygen and nurse escort on request": {
    Lang.fr: "Oxygène et infirmier sur demande",
    Lang.ar: "أكسجين ومرافقة ممرض عند الطلب",
    Lang.ru: "Кислород и сопровождение медсестры по запросу"
  },
  "Full treatment package": {
    Lang.fr: "Forfait traitement complet",
    Lang.ar: "باقة العلاج الكاملة",
    Lang.ru: "Полный пакет на время лечения"
  },
  "From arrival to departure": {
    Lang.fr: "De l'arrivée au départ",
    Lang.ar: "من الوصول حتى المغادرة",
    Lang.ru: "От прилёта до вылета"
  },
  "Every ride of your stay in one booking: airport, hotel and hospital, at one price.":
      {
    Lang.fr:
        "Tous les trajets de votre séjour en une seule réservation : aéroport, hôtel et hôpital, à un prix unique.",
    Lang.ar:
        "جميع رحلات إقامتك في حجز واحد: المطار والفندق والمستشفى، بسعر واحد.",
    Lang.ru:
        "Все поездки за время пребывания в одном бронировании: аэропорт, отель и больница по единой цене."
  },
  "All transfers planned for you": {
    Lang.fr: "Tous les transferts planifiés pour vous",
    Lang.ar: "جميع التنقلات مخططة لك",
    Lang.ru: "Все трансферы спланированы за вас"
  },
  "One personal coordinator": {
    Lang.fr: "Un coordinateur personnel",
    Lang.ar: "منسق شخصي واحد",
    Lang.ru: "Один личный координатор"
  },
  "Driver name, plate and live location on WhatsApp": {
    Lang.fr: "Nom du chauffeur, plaque et position en direct sur WhatsApp",
    Lang.ar: "اسم السائق ورقم اللوحة والموقع المباشر عبر واتساب",
    Lang.ru: "Имя водителя, номер машины и местоположение в WhatsApp"
  },
  "Support 24/7": {
    Lang.fr: "Assistance 24 h/24, 7 j/7",
    Lang.ar: "دعم على مدار الساعة",
    Lang.ru: "Поддержка 24/7"
  },
  "Interpreter": {
    Lang.fr: "Interprète",
    Lang.ar: "مترجم",
    Lang.ru: "Переводчик"
  },
  "VIP car": {
    Lang.fr: "Voiture VIP",
    Lang.ar: "سيارة VIP",
    Lang.ru: "VIP-автомобиль"
  },
  "Nurse escort": {
    Lang.fr: "Accompagnement infirmier",
    Lang.ar: "مرافقة ممرض",
    Lang.ru: "Сопровождение медсестры"
  },
  "Oxygen on board": {
    Lang.fr: "Oxygène à bord",
    Lang.ar: "أكسجين في المركبة",
    Lang.ru: "Кислород в машине"
  },
  "Companion seat": {
    Lang.fr: "Place pour accompagnant",
    Lang.ar: "مقعد للمرافق",
    Lang.ru: "Место для сопровождающего"
  },
  "Child seat": {
    Lang.fr: "Siège enfant",
    Lang.ar: "مقعد أطفال",
    Lang.ru: "Детское кресло"
  },
  "Our transport services": {
    Lang.fr: "Nos services de transport",
    Lang.ar: "خدمات النقل لدينا",
    Lang.ru: "Наши транспортные услуги"
  },
  "Airport, hotel and hospital: we take care of every ride during your treatment.":
      {
    Lang.fr:
        "Aéroport, hôtel et hôpital : nous nous occupons de chaque trajet pendant votre traitement.",
    Lang.ar: "المطار والفندق والمستشفى: نهتم بكل رحلة خلال فترة علاجك.",
    Lang.ru:
        "Аэропорт, отель и больница: мы берём на себя каждую поездку во время лечения."
  },
  "Add to any ride": {
    Lang.fr: "À ajouter à tout trajet",
    Lang.ar: "أضفها إلى أي رحلة",
    Lang.ru: "Можно добавить к любой поездке"
  },
  "Book this service": {
    Lang.fr: "Réserver ce service",
    Lang.ar: "احجز هذه الخدمة",
    Lang.ru: "Заказать эту услугу"
  },

  // Homepage: comments, branches, drivers.
  "Koru Hospital Çukurambar": {
    Lang.fr: "Hôpital Koru Çukurambar",
    Lang.ar: "مستشفى كورو جوكورامبار",
    Lang.ru: "Больница Koru Чукурамбар"
  },
  "Koru Hospital Sincan": {
    Lang.fr: "Hôpital Koru Sincan",
    Lang.ar: "مستشفى كورو سينجان",
    Lang.ru: "Больница Koru Синджан"
  },
  "Koru Hospital Kavaklıdere": {
    Lang.fr: "Hôpital Koru Kavaklıdere",
    Lang.ar: "مستشفى كورو كافاكليدره",
    Lang.ru: "Больница Koru Каваклыдере"
  },
  "Next": {Lang.fr: "Suivant", Lang.ar: "التالي", Lang.ru: "Далее"},
  "Leave feedback": {
    Lang.fr: "Laisser un avis",
    Lang.ar: "اترك تعليقًا",
    Lang.ru: "Оставить отзыв"
  },
  "What patients say": {
    Lang.fr: "Ce que disent les patients",
    Lang.ar: "ماذا يقول المرضى",
    Lang.ru: "Отзывы пациентов"
  },
  "Did you ride with us? Tell us how it went.": {
    Lang.fr:
        "Vous avez voyagé avec nous ? Racontez-nous comment cela s'est passé.",
    Lang.ar: "هل سافرت معنا؟ أخبرنا كيف كانت التجربة.",
    Lang.ru: "Вы ездили с нами? Расскажите, как всё прошло."
  },
  "A patient": {
    Lang.fr: "Un patient",
    Lang.ar: "أحد المرضى",
    Lang.ru: "Пациент"
  },
  "Find your branch": {
    Lang.fr: "Trouver votre établissement",
    Lang.ar: "ابحث عن فرعك",
    Lang.ru: "Найдите свой филиал"
  },
  "Branch": {Lang.fr: "Établissement", Lang.ar: "الفرع", Lang.ru: "Филиал"},
  "Address": {Lang.fr: "Adresse", Lang.ar: "العنوان", Lang.ru: "Адрес"},
  "Transit": {
    Lang.fr: "Transports en commun",
    Lang.ar: "المواصلات العامة",
    Lang.ru: "Общественный транспорт"
  },
  "Parking": {
    Lang.fr: "Parking",
    Lang.ar: "موقف السيارات",
    Lang.ru: "Парковка"
  },
  "Get directions": {
    Lang.fr: "Itinéraire",
    Lang.ar: "احصل على الاتجاهات",
    Lang.ru: "Построить маршрут"
  },
  "Our drivers": {
    Lang.fr: "Nos chauffeurs",
    Lang.ar: "سائقونا",
    Lang.ru: "Наши водители"
  },
  "Koru Hospital's own drivers, trained to help patients safely in and out of the vehicle.":
      {
    Lang.fr:
        "Les chauffeurs de l'hôpital Koru, formés pour aider les patients à monter et descendre du véhicule en toute sécurité.",
    Lang.ar:
        "سائقو مستشفى كورو، مدرَّبون على مساعدة المرضى في الصعود إلى المركبة والنزول منها بأمان.",
    Lang.ru:
        "Собственные водители больницы Koru, обученные безопасно помогать пациентам садиться в машину и выходить из неё."
  },
  "Medical Transport Driver": {
    Lang.fr: "Chauffeur de transport médical",
    Lang.ar: "سائق نقل طبي",
    Lang.ru: "Водитель медицинского транспорта"
  },
  "Accessible Transport Driver": {
    Lang.fr: "Chauffeur de transport adapté",
    Lang.ar: "سائق نقل لذوي الاحتياجات الخاصة",
    Lang.ru: "Водитель адаптированного транспорта"
  },
  "Airport Transfer Driver": {
    Lang.fr: "Chauffeur de transfert aéroport",
    Lang.ar: "سائق النقل من وإلى المطار",
    Lang.ru: "Водитель трансфера из аэропорта"
  },
  "Patient Transfer Driver": {
    Lang.fr: "Chauffeur de transfert de patients",
    Lang.ar: "سائق نقل المرضى",
    Lang.ru: "Водитель по перевозке пациентов"
  },
  "With Koru since {}": {
    Lang.fr: "Chez Koru depuis {}",
    Lang.ar: "مع كورو منذ {}",
    Lang.ru: "В Koru с {}"
  },

  // Contact page.
  "Contact us": {
    Lang.fr: "Nous contacter",
    Lang.ar: "اتصل بنا",
    Lang.ru: "Свяжитесь с нами"
  },
  "Our transport coordinators answer 24/7.": {
    Lang.fr: "Nos coordinateurs transport répondent 24 h/24, 7 j/7.",
    Lang.ar: "منسقو النقل لدينا يردون على مدار الساعة.",
    Lang.ru: "Наши координаторы отвечают 24/7."
  },
  "Phone": {Lang.fr: "Téléphone", Lang.ar: "الهاتف", Lang.ru: "Телефон"},
  "Koru Hospital — three locations in Ankara": {
    Lang.fr: "Koru Hospital — trois sites à Ankara",
    Lang.ar: "مستشفى كورو — ثلاثة مواقع في أنقرة",
    Lang.ru: "Больница Koru — три филиала в Анкаре"
  },
  "Koru Hospital is a healthcare institution in Ankara, Türkiye, associated with the vision and expertise of two doctors: Prof. Dr. Hassan Birri, a urologist, and Prof. Dr. Aydın Birri, a gynecologist.":
      {
    Lang.fr:
        "Koru Hospital est un établissement de santé à Ankara, en Turquie, porté par la vision et l'expertise de deux médecins : le Pr Dr Hassan Birri, urologue, et le Pr Dr Aydın Birri, gynécologue.",
    Lang.ar:
        "مستشفى كورو مؤسسة صحية في أنقرة، تركيا، ترتبط برؤية وخبرة طبيبين: البروفيسور الدكتور حسن بيري، أخصائي المسالك البولية، والبروفيسور الدكتور آيدن بيري، أخصائي أمراض النساء.",
    Lang.ru:
        "Больница Koru — медицинское учреждение в Анкаре (Турция), связанное с видением и опытом двух врачей: проф. д-ра Хасана Бирри, уролога, и проф. д-ра Айдына Бирри, гинеколога."
  },
  "Today, Koru Hospital serves patients across three locations in Ankara, providing access to medical services and supporting patients throughout their healthcare journey.":
      {
    Lang.fr:
        "Aujourd'hui, Koru Hospital accueille les patients sur trois sites à Ankara, donne accès aux soins médicaux et accompagne les patients tout au long de leur parcours de santé.",
    Lang.ar:
        "يخدم مستشفى كورو اليوم المرضى في ثلاثة مواقع في أنقرة، ويوفر الوصول إلى الخدمات الطبية ويدعم المرضى طوال رحلتهم العلاجية.",
    Lang.ru:
        "Сегодня больница Koru принимает пациентов в трёх филиалах в Анкаре, обеспечивая доступ к медицинским услугам и поддерживая пациентов на всём пути лечения."
  },
  "Main hospital": {
    Lang.fr: "Hôpital principal",
    Lang.ar: "المستشفى الرئيسي",
    Lang.ru: "Главная больница"
  },
  "The main hospital location, offering a range of medical specialties and services. It serves as the primary destination for patients seeking medical care through the Koru network.":
      {
    Lang.fr:
        "Le site principal, qui propose un large éventail de spécialités et de services médicaux. C'est la destination principale des patients qui se font soigner dans le réseau Koru.",
    Lang.ar:
        "الموقع الرئيسي للمستشفى، ويقدم مجموعة من التخصصات والخدمات الطبية. وهو الوجهة الأساسية للمرضى الباحثين عن الرعاية الطبية عبر شبكة كورو.",
    Lang.ru:
        "Главный филиал с широким выбором медицинских специальностей и услуг. Основное место, куда обращаются пациенты сети Koru."
  },
  "The Sincan location extends access to Koru Hospital's healthcare services, serving patients in the Sincan area and surrounding communities.":
      {
    Lang.fr:
        "Le site de Sincan étend l'accès aux soins de Koru Hospital aux patients de Sincan et des environs.",
    Lang.ar:
        "يوسّع موقع سنجان نطاق الوصول إلى خدمات مستشفى كورو الصحية، ويخدم المرضى في منطقة سنجان والمناطق المحيطة بها.",
    Lang.ru:
        "Филиал в Синджане делает услуги больницы Koru доступнее для пациентов Синджана и соседних районов."
  },
  "The Kavaklıdere location provides another point of access for patients seeking healthcare services in Ankara.":
      {
    Lang.fr:
        "Le site de Kavaklıdere offre un autre point d'accès aux patients qui cherchent des soins à Ankara.",
    Lang.ar:
        "يوفر موقع كافاكليدره نقطة وصول أخرى للمرضى الباحثين عن خدمات الرعاية الصحية في أنقرة.",
    Lang.ru:
        "Филиал в Каваклыдере — ещё одно место, где пациенты могут получить медицинскую помощь в Анкаре."
  },
  "Koru Transport — connecting patients to care": {
    Lang.fr: "Koru Transport — relier les patients aux soins",
    Lang.ar: "كورو للنقل — نوصل المرضى إلى الرعاية",
    Lang.ru: "Koru Transport — путь пациента к лечению"
  },
  "Koru Transport helps patients travel conveniently between Ankara Airport, Koru Hospital's three locations, hotels, and other destinations. Our goal is to make every journey comfortable, reliable, and stress-free.":
      {
    Lang.fr:
        "Koru Transport aide les patients à se déplacer facilement entre l'aéroport d'Ankara, les trois sites de Koru Hospital, les hôtels et d'autres destinations. Notre objectif : des trajets confortables, fiables et sans stress.",
    Lang.ar:
        "تساعد كورو للنقل المرضى على التنقل بسهولة بين مطار أنقرة ومواقع مستشفى كورو الثلاثة والفنادق ووجهات أخرى. هدفنا أن تكون كل رحلة مريحة وموثوقة وخالية من التوتر.",
    Lang.ru:
        "Koru Transport помогает пациентам удобно добираться между аэропортом Анкары, тремя филиалами больницы Koru, гостиницами и другими местами. Наша цель — сделать каждую поездку комфортной, надёжной и спокойной."
  },
  "Three locations. One commitment: patient care.": {
    Lang.fr: "Trois sites. Un seul engagement : le soin des patients.",
    Lang.ar: "ثلاثة مواقع. التزام واحد: رعاية المرضى.",
    Lang.ru: "Три филиала. Одна цель — забота о пациентах."
  },
  "Message sent. We will reply soon.": {
    Lang.fr: "Message envoyé. Nous vous répondrons bientôt.",
    Lang.ar: "تم إرسال الرسالة. سنرد عليك قريبًا.",
    Lang.ru: "Сообщение отправлено. Мы скоро ответим."
  },
  "Question about a booking": {
    Lang.fr: "Question sur une réservation",
    Lang.ar: "سؤال عن حجز",
    Lang.ru: "Вопрос о бронировании"
  },
  "Change or cancel a booking": {
    Lang.fr: "Modifier ou annuler une réservation",
    Lang.ar: "تعديل حجز أو إلغاؤه",
    Lang.ru: "Изменить или отменить бронирование"
  },
  "Other": {Lang.fr: "Autre", Lang.ar: "أخرى", Lang.ru: "Другое"},
  "Send us a message": {
    Lang.fr: "Envoyez-nous un message",
    Lang.ar: "أرسل لنا رسالة",
    Lang.ru: "Напишите нам"
  },
  "Your name": {Lang.fr: "Votre nom", Lang.ar: "اسمك", Lang.ru: "Ваше имя"},
  "Phone or email": {
    Lang.fr: "Téléphone ou e-mail",
    Lang.ar: "الهاتف أو البريد الإلكتروني",
    Lang.ru: "Телефон или эл. почта"
  },
  "Topic": {Lang.fr: "Sujet", Lang.ar: "الموضوع", Lang.ru: "Тема"},
  "Message": {Lang.fr: "Message", Lang.ar: "الرسالة", Lang.ru: "Сообщение"},
  "Send message": {
    Lang.fr: "Envoyer le message",
    Lang.ar: "إرسال الرسالة",
    Lang.ru: "Отправить сообщение"
  },
  "Our branches": {
    Lang.fr: "Nos établissements",
    Lang.ar: "فروعنا",
    Lang.ru: "Наши филиалы"
  },

  // Booking page.
  "Book transport": {
    Lang.fr: "Réserver un transport",
    Lang.ar: "احجز وسيلة نقل",
    Lang.ru: "Заказать транспорт"
  },
  "Three short steps. A coordinator calls you to confirm.": {
    Lang.fr:
        "Trois étapes rapides. Un coordinateur vous appelle pour confirmer.",
    Lang.ar: "ثلاث خطوات قصيرة. سيتصل بك منسق للتأكيد.",
    Lang.ru: "Три коротких шага. Координатор позвонит для подтверждения."
  },
  "Transport type": {
    Lang.fr: "Type de transport",
    Lang.ar: "نوع النقل",
    Lang.ru: "Тип транспорта"
  },
  "Patient": {Lang.fr: "Patient", Lang.ar: "المريض", Lang.ru: "Пациент"},
  "Pickup & time": {
    Lang.fr: "Prise en charge et heure",
    Lang.ar: "مكان الانطلاق والوقت",
    Lang.ru: "Посадка и время"
  },
  "Back": {Lang.fr: "Retour", Lang.ar: "رجوع", Lang.ru: "Назад"},
  "Send request": {
    Lang.fr: "Envoyer la demande",
    Lang.ar: "إرسال الطلب",
    Lang.ru: "Отправить заявку"
  },
  "Stretcher transfer with medical staff.": {
    Lang.fr: "Transfert sur brancard avec personnel médical.",
    Lang.ar: "نقل على نقالة مع طاقم طبي.",
    Lang.ru: "Перевозка на носилках с медперсоналом."
  },
  "Ramp or lift, room for a companion.": {
    Lang.fr: "Rampe ou élévateur, place pour un accompagnant.",
    Lang.ar: "منحدر أو رافعة، ومكان لمرافق.",
    Lang.ru: "Пандус или подъёмник, место для сопровождающего."
  },
  "For patients who can walk on their own.": {
    Lang.fr: "Pour les patients qui marchent seuls.",
    Lang.ar: "للمرضى القادرين على المشي بمفردهم.",
    Lang.ru: "Для пациентов, которые могут ходить самостоятельно."
  },
  "Meet at arrivals, drive to the hospital or hotel.": {
    Lang.fr: "Accueil aux arrivées, trajet vers l'hôpital ou l'hôtel.",
    Lang.ar: "استقبال في صالة الوصول وتوصيل إلى المستشفى أو الفندق.",
    Lang.ru: "Встреча в зоне прилёта, поездка в больницу или отель."
  },
  "Please choose a transport type.": {
    Lang.fr: "Veuillez choisir un type de transport.",
    Lang.ar: "يرجى اختيار نوع النقل.",
    Lang.ru: "Пожалуйста, выберите тип транспорта."
  },
  "Patient full name": {
    Lang.fr: "Nom complet du patient",
    Lang.ar: "الاسم الكامل للمريض",
    Lang.ru: "ФИО пациента"
  },
  "Contact phone": {
    Lang.fr: "Téléphone de contact",
    Lang.ar: "رقم هاتف للتواصل",
    Lang.ru: "Контактный телефон"
  },
  "Mobility needs": {
    Lang.fr: "Besoins de mobilité",
    Lang.ar: "احتياجات الحركة",
    Lang.ru: "Потребности при передвижении"
  },
  "Notes for the team (optional)": {
    Lang.fr: "Notes pour l'équipe (facultatif)",
    Lang.ar: "ملاحظات للفريق (اختياري)",
    Lang.ru: "Заметки для команды (необязательно)"
  },
  "Destination branch": {
    Lang.fr: "Établissement de destination",
    Lang.ar: "فرع الوجهة",
    Lang.ru: "Филиал назначения"
  },
  "Time": {Lang.fr: "Heure", Lang.ar: "الوقت", Lang.ru: "Время"},
  "I agree that my personal and health data is processed under KVKK to arrange this transport.":
      {
    Lang.fr:
        "J'accepte que mes données personnelles et de santé soient traitées conformément à la KVKK pour organiser ce transport.",
    Lang.ar:
        "أوافق على معالجة بياناتي الشخصية والصحية وفقًا لقانون KVKK لترتيب هذا النقل.",
    Lang.ru:
        "Я согласен(на) на обработку моих персональных данных и данных о здоровье согласно KVKK для организации этой перевозки."
  },
  "Please accept the KVKK notice.": {
    Lang.fr: "Veuillez accepter la notice KVKK.",
    Lang.ar: "يرجى الموافقة على إشعار KVKK.",
    Lang.ru: "Пожалуйста, примите уведомление KVKK."
  },
  "Transport": {Lang.fr: "Transport", Lang.ar: "النقل", Lang.ru: "Транспорт"},
  "Needs": {Lang.fr: "Besoins", Lang.ar: "الاحتياجات", Lang.ru: "Потребности"},
  "Summary": {Lang.fr: "Récapitulatif", Lang.ar: "الملخص", Lang.ru: "Сводка"},
  "Request received": {
    Lang.fr: "Demande reçue",
    Lang.ar: "تم استلام الطلب",
    Lang.ru: "Заявка получена"
  },
  "Reference: {}. A coordinator will call {} to confirm your ride.": {
    Lang.fr:
        "Référence : {}. Un coordinateur appellera le {} pour confirmer votre trajet.",
    Lang.ar: "رقم المرجع: {}. سيتصل منسق بالرقم {} لتأكيد رحلتك.",
    Lang.ru:
        "Номер: {}. Координатор позвонит по номеру {}, чтобы подтвердить поездку."
  },
  "New booking": {
    Lang.fr: "Nouvelle réservation",
    Lang.ar: "حجز جديد",
    Lang.ru: "Новое бронирование"
  },

  // Admin dashboard.
  "Feedback": {Lang.fr: "Avis", Lang.ar: "التعليقات", Lang.ru: "Отзывы"},
  "Dashboard": {
    Lang.fr: "Tableau de bord",
    Lang.ar: "لوحة التحكم",
    Lang.ru: "Панель управления"
  },
  "Bookings": {
    Lang.fr: "Réservations",
    Lang.ar: "الحجوزات",
    Lang.ru: "Бронирования"
  },
  "Move each booking to the next stage.": {
    Lang.fr: "Faites passer chaque réservation à l'étape suivante.",
    Lang.ar: "انقل كل حجز إلى المرحلة التالية.",
    Lang.ru: "Переводите каждое бронирование на следующий этап."
  },
  "Confirm": {Lang.fr: "Confirmer", Lang.ar: "تأكيد", Lang.ru: "Подтвердить"},
  "Reserve": {Lang.fr: "Réserver", Lang.ar: "حجز", Lang.ru: "Забронировать"},
  "Assign driver": {
    Lang.fr: "Attribuer un chauffeur",
    Lang.ar: "تعيين سائق",
    Lang.ru: "Назначить водителя"
  },
  "No bookings here.": {
    Lang.fr: "Aucune réservation ici.",
    Lang.ar: "لا توجد حجوزات هنا.",
    Lang.ru: "Здесь нет бронирований."
  },
  "Ref": {Lang.fr: "Réf.", Lang.ar: "المرجع", Lang.ru: "Номер"},
  "Route": {Lang.fr: "Trajet", Lang.ar: "المسار", Lang.ru: "Маршрут"},
  "Date & time": {
    Lang.fr: "Date et heure",
    Lang.ar: "التاريخ والوقت",
    Lang.ru: "Дата и время"
  },
  "Vehicle / driver": {
    Lang.fr: "Véhicule / chauffeur",
    Lang.ar: "المركبة / السائق",
    Lang.ru: "Машина / водитель"
  },
  "Action": {Lang.fr: "Action", Lang.ar: "الإجراء", Lang.ru: "Действие"},
  "Done": {Lang.fr: "Terminé", Lang.ar: "تم", Lang.ru: "Готово"},
  "View website": {
    Lang.fr: "Voir le site",
    Lang.ar: "عرض الموقع",
    Lang.ru: "Открыть сайт"
  },
  "Site color": {
    Lang.fr: "Couleur du site",
    Lang.ar: "لون الموقع",
    Lang.ru: "Цвет сайта"
  },
  "Sign out": {
    Lang.fr: "Se déconnecter",
    Lang.ar: "تسجيل الخروج",
    Lang.ru: "Выйти"
  },
  "Read patient comments. Approved comments appear on the homepage with the first name only.":
      {
    Lang.fr:
        "Lisez les commentaires des patients. Les commentaires approuvés apparaissent sur l'accueil avec le prénom uniquement.",
    Lang.ar:
        "اقرأ تعليقات المرضى. تظهر التعليقات المعتمدة في الصفحة الرئيسية بالاسم الأول فقط.",
    Lang.ru:
        "Читайте отзывы пациентов. Одобренные отзывы появляются на главной только с именем."
  },
  "{} comments": {
    Lang.fr: "{} commentaires",
    Lang.ar: "{} تعليقات",
    Lang.ru: "Отзывов: {}"
  },
  "No comments yet.": {
    Lang.fr: "Aucun commentaire pour l'instant.",
    Lang.ar: "لا توجد تعليقات بعد.",
    Lang.ru: "Отзывов пока нет."
  },
  "On homepage": {
    Lang.fr: "Sur l'accueil",
    Lang.ar: "في الصفحة الرئيسية",
    Lang.ru: "На главной"
  },
  "Hide from website": {
    Lang.fr: "Retirer du site",
    Lang.ar: "إخفاء من الموقع",
    Lang.ru: "Скрыть с сайта"
  },
  "Show on website": {
    Lang.fr: "Afficher sur le site",
    Lang.ar: "عرض على الموقع",
    Lang.ru: "Показать на сайте"
  },
  "Delete": {Lang.fr: "Supprimer", Lang.ar: "حذف", Lang.ru: "Удалить"},
  "Vehicle type": {
    Lang.fr: "Type de véhicule",
    Lang.ar: "نوع المركبة",
    Lang.ru: "Тип машины"
  },
  "Cancel": {Lang.fr: "Annuler", Lang.ar: "إلغاء", Lang.ru: "Отмена"},
  "Save & reserve": {
    Lang.fr: "Enregistrer et réserver",
    Lang.ar: "حفظ وحجز",
    Lang.ru: "Сохранить и забронировать"
  },
  "Vehicle plate": {
    Lang.fr: "Plaque du véhicule",
    Lang.ar: "رقم لوحة المركبة",
    Lang.ru: "Номер машины"
  },
  "Driver name": {
    Lang.fr: "Nom du chauffeur",
    Lang.ar: "اسم السائق",
    Lang.ru: "Имя водителя"
  },
  "Save & assign": {
    Lang.fr: "Enregistrer et attribuer",
    Lang.ar: "حفظ وتعيين",
    Lang.ru: "Сохранить и назначить"
  },

  // Header, footer and shared parts.
  "Book": {Lang.fr: "Réserver", Lang.ar: "الحجز", Lang.ru: "Заказ"},
  "Directions": {
    Lang.fr: "Accès",
    Lang.ar: "الاتجاهات",
    Lang.ru: "Как добраться"
  },
  "Contact": {Lang.fr: "Contact", Lang.ar: "اتصل بنا", Lang.ru: "Контакты"},
  "Call {}": {
    Lang.fr: "Appeler le {}",
    Lang.ar: "اتصل {}",
    Lang.ru: "Позвонить {}"
  },
  "Menu": {Lang.fr: "Menu", Lang.ar: "القائمة", Lang.ru: "Меню"},
  "Language": {Lang.fr: "Langue", Lang.ar: "اللغة", Lang.ru: "Язык"},
  "Koru Hospital": {
    Lang.fr: "Hôpital Koru",
    Lang.ar: "مستشفى كورو",
    Lang.ru: "Больница Koru"
  },
  "KVKK / Privacy": {
    Lang.fr: "KVKK / Confidentialité",
    Lang.ar: "KVKK / الخصوصية",
    Lang.ru: "KVKK / Конфиденциальность"
  },
  "Emergency": {
    Lang.fr: "Urgence",
    Lang.ar: "الطوارئ",
    Lang.ru: "Экстренная помощь"
  },
  "Staff login": {
    Lang.fr: "Accès personnel",
    Lang.ar: "دخول الموظفين",
    Lang.ru: "Вход для сотрудников"
  },
  "Emergency?": {
    Lang.fr: "Urgence ?",
    Lang.ar: "حالة طارئة؟",
    Lang.ru: "Экстренный случай?"
  },
  "This form is not for emergencies. Call 112 right away.": {
    Lang.fr:
        "Ce formulaire n'est pas destiné aux urgences. Appelez immédiatement le 112.",
    Lang.ar: "هذا النموذج ليس للحالات الطارئة. اتصل بالرقم 112 فورًا.",
    Lang.ru: "Эта форма не для экстренных случаев. Немедленно звоните 112."
  },
  "Call 112": {
    Lang.fr: "Appeler le 112",
    Lang.ar: "اتصل بـ 112",
    Lang.ru: "Позвонить 112"
  },
  "Tap the map to set your pickup point": {
    Lang.fr: "Touchez la carte pour indiquer votre point de prise en charge",
    Lang.ar: "اضغط على الخريطة لتحديد مكان الانطلاق",
    Lang.ru: "Нажмите на карту, чтобы указать место посадки"
  },

  // Color picker.
  "Change color": {
    Lang.fr: "Changer la couleur",
    Lang.ar: "تغيير اللون",
    Lang.ru: "Изменить цвет"
  },
  "Use a code like #1F4FD1": {
    Lang.fr: "Utilisez un code comme #1F4FD1",
    Lang.ar: "استخدم رمزًا مثل #1F4FD1",
    Lang.ru: "Введите код, например #1F4FD1"
  },
  "Too light: white text would be hard to read": {
    Lang.fr: "Trop clair : le texte blanc serait difficile à lire",
    Lang.ar: "فاتح جدًا: سيصعب قراءة النص الأبيض",
    Lang.ru: "Слишком светлый: белый текст будет плохо читаться"
  },
  "Pick the main color. White stays the background.": {
    Lang.fr: "Choisissez la couleur principale. Le fond reste blanc.",
    Lang.ar: "اختر اللون الرئيسي. تبقى الخلفية بيضاء.",
    Lang.ru: "Выберите основной цвет. Фон останется белым."
  },
  "Custom color code": {
    Lang.fr: "Code couleur personnalisé",
    Lang.ar: "رمز لون مخصص",
    Lang.ru: "Свой код цвета"
  },
  "Apply": {Lang.fr: "Appliquer", Lang.ar: "تطبيق", Lang.ru: "Применить"},
  "Reset to Koru navy": {
    Lang.fr: "Revenir au bleu marine Koru",
    Lang.ar: "العودة إلى أزرق كورو الداكن",
    Lang.ru: "Вернуть тёмно-синий Koru"
  },
  "Koru navy": {
    Lang.fr: "Bleu marine Koru",
    Lang.ar: "أزرق كورو الداكن",
    Lang.ru: "Тёмно-синий Koru"
  },
  "Royal blue": {
    Lang.fr: "Bleu roi",
    Lang.ar: "أزرق ملكي",
    Lang.ru: "Королевский синий"
  },
  "Sky blue": {
    Lang.fr: "Bleu ciel",
    Lang.ar: "أزرق سماوي",
    Lang.ru: "Небесно-голубой"
  },
  "Teal": {Lang.fr: "Bleu canard", Lang.ar: "أزرق مخضر", Lang.ru: "Бирюзовый"},
  "Green": {Lang.fr: "Vert", Lang.ar: "أخضر", Lang.ru: "Зелёный"},
  "Indigo": {Lang.fr: "Indigo", Lang.ar: "نيلي", Lang.ru: "Индиго"},
  "Purple": {Lang.fr: "Violet", Lang.ar: "بنفسجي", Lang.ru: "Фиолетовый"},
  "Rose": {Lang.fr: "Rose", Lang.ar: "وردي", Lang.ru: "Розовый"},
  "Orange": {Lang.fr: "Orange", Lang.ar: "برتقالي", Lang.ru: "Оранжевый"},

  // Patient feedback page.
  "Punctuality": {
    Lang.fr: "Ponctualité",
    Lang.ar: "الالتزام بالمواعيد",
    Lang.ru: "Пунктуальность"
  },
  "Driver courtesy": {
    Lang.fr: "Courtoisie du chauffeur",
    Lang.ar: "لباقة السائق",
    Lang.ru: "Вежливость водителя"
  },
  "Vehicle comfort & cleanliness": {
    Lang.fr: "Confort et propreté du véhicule",
    Lang.ar: "راحة المركبة ونظافتها",
    Lang.ru: "Комфорт и чистота автомобиля"
  },
  "Safe driving": {
    Lang.fr: "Conduite sûre",
    Lang.ar: "القيادة الآمنة",
    Lang.ru: "Безопасное вождение"
  },
  "Booking & communication": {
    Lang.fr: "Réservation et communication",
    Lang.ar: "الحجز والتواصل",
    Lang.ru: "Бронирование и связь"
  },
  "Help getting in and out": {
    Lang.fr: "Aide à la montée et à la descente",
    Lang.ar: "المساعدة في الصعود والنزول",
    Lang.ru: "Помощь при посадке и высадке"
  },
  "Poor": {
    Lang.fr: "Mauvais",
    Lang.ar: "ضعيف",
    Lang.ru: "Плохо"
  },
  "Fair": {
    Lang.fr: "Passable",
    Lang.ar: "مقبول",
    Lang.ru: "Удовлетворительно"
  },
  "Good": {
    Lang.fr: "Bien",
    Lang.ar: "جيد",
    Lang.ru: "Хорошо"
  },
  "Very good": {
    Lang.fr: "Très bien",
    Lang.ar: "جيد جدًا",
    Lang.ru: "Очень хорошо"
  },
  "Excellent": {
    Lang.fr: "Excellent",
    Lang.ar: "ممتاز",
    Lang.ru: "Отлично"
  },
  "Tap a star to rate": {
    Lang.fr: "Touchez une étoile pour noter",
    Lang.ar: "اضغط على نجمة للتقييم",
    Lang.ru: "Нажмите на звезду, чтобы оценить"
  },
  "Your feedback could not be sent. Check the internet connection and try again.": {
    Lang.fr: "Votre avis n'a pas pu être envoyé. Vérifiez la connexion internet et réessayez.",
    Lang.ar: "تعذّر إرسال رأيك. تحقّق من الاتصال بالإنترنت وحاول مرة أخرى.",
    Lang.ru: "Не удалось отправить отзыв. Проверьте подключение к интернету и попробуйте снова."
  },
  "PATIENT FEEDBACK": {
    Lang.fr: "AVIS DES PATIENTS",
    Lang.ar: "آراء المرضى",
    Lang.ru: "ОТЗЫВЫ ПАЦИЕНТОВ"
  },
  "How was your journey with Koru Transport?": {
    Lang.fr: "Comment s'est passé votre trajet avec Koru Transport ?",
    Lang.ar: "كيف كانت رحلتك مع Koru Transport؟",
    Lang.ru: "Как прошла ваша поездка с Koru Transport?"
  },
  "Your opinion helps us care for every patient better. It takes about one minute and your name is optional.": {
    Lang.fr: "Votre avis nous aide à mieux prendre soin de chaque patient. Cela prend environ une minute et votre nom est facultatif.",
    Lang.ar: "رأيك يساعدنا على رعاية كل مريض بشكل أفضل. يستغرق الأمر دقيقة تقريبًا، وكتابة اسمك اختيارية.",
    Lang.ru: "Ваше мнение помогает нам лучше заботиться о каждом пациенте. Это займёт около минуты, имя указывать не обязательно."
  },
  "Overall, how would you rate our service?": {
    Lang.fr: "Dans l'ensemble, comment évaluez-vous notre service ?",
    Lang.ar: "بشكل عام، كيف تقيّم خدمتنا؟",
    Lang.ru: "В целом, как вы оцениваете наш сервис?"
  },
  "Which parts of the service is your feedback about?": {
    Lang.fr: "Sur quels aspects du service porte votre avis ?",
    Lang.ar: "ما أجزاء الخدمة التي يتعلّق بها رأيك؟",
    Lang.ru: "К каким частям сервиса относится ваш отзыв?"
  },
  "Optional · choose any": {
    Lang.fr: "Facultatif · plusieurs choix possibles",
    Lang.ar: "اختياري · يمكنك اختيار أكثر من خيار",
    Lang.ru: "Необязательно · можно выбрать несколько"
  },
  "Tell us more": {
    Lang.fr: "Dites-nous en plus",
    Lang.ar: "أخبرنا بالمزيد",
    Lang.ru: "Расскажите подробнее"
  },
  "Optional": {
    Lang.fr: "Facultatif",
    Lang.ar: "اختياري",
    Lang.ru: "Необязательно"
  },
  "About your ride": {
    Lang.fr: "À propos de votre trajet",
    Lang.ar: "عن رحلتك",
    Lang.ru: "О вашей поездке"
  },
  "Choose…": {
    Lang.fr: "Choisir…",
    Lang.ar: "اختر…",
    Lang.ru: "Выберите…"
  },
  "Booking reference": {
    Lang.fr: "Numéro de réservation",
    Lang.ar: "رقم الحجز",
    Lang.ru: "Номер бронирования"
  },
  "Our patient services team reads every response. We may share a comment on our website with your first name only. Please do not write medical details.": {
    Lang.fr: "Notre service patients lit chaque réponse. Nous pouvons publier un commentaire sur notre site avec votre prénom uniquement. Merci de ne pas indiquer d'informations médicales.",
    Lang.ar: "يقرأ فريق خدمات المرضى كل ردّ. قد ننشر تعليقًا على موقعنا باسمك الأول فقط. يُرجى عدم كتابة معلومات طبية.",
    Lang.ru: "Служба по работе с пациентами читает каждый ответ. Мы можем опубликовать отзыв на сайте только с вашим именем. Пожалуйста, не указывайте медицинские сведения."
  },
  "Please choose a star rating (step 1) before sending.": {
    Lang.fr: "Veuillez choisir une note (étape 1) avant d'envoyer.",
    Lang.ar: "يُرجى اختيار تقييم بالنجوم (الخطوة 1) قبل الإرسال.",
    Lang.ru: "Пожалуйста, выберите оценку (шаг 1) перед отправкой."
  },
  "Thank you for your feedback": {
    Lang.fr: "Merci pour votre avis",
    Lang.ar: "شكرًا لك على رأيك",
    Lang.ru: "Спасибо за ваш отзыв"
  },
  "Our patient services team will read it. We wish you good health.": {
    Lang.fr: "Notre service patients le lira. Nous vous souhaitons une bonne santé.",
    Lang.ar: "سيقرؤه فريق خدمات المرضى. نتمنى لك دوام الصحة.",
    Lang.ru: "Служба по работе с пациентами его прочитает. Желаем вам крепкого здоровья."
  },
  "New feedback": {
    Lang.fr: "Nouvel avis",
    Lang.ar: "رأي جديد",
    Lang.ru: "Новый отзыв"
  },
  "This screen will clear in {} seconds.": {
    Lang.fr: "Cet écran s'effacera dans {} secondes.",
    Lang.ar: "سيتم مسح هذه الشاشة خلال {} ثانية.",
    Lang.ru: "Экран очистится через {} сек."
  },
  "Are you a patient or visitor?": {
    Lang.fr: "Vous êtes patient ou visiteur ?",
    Lang.ar: "هل أنت مريض أو زائر؟",
    Lang.ru: "Вы пациент или посетитель?"
  },
  "Share your feedback": {
    Lang.fr: "Partagez votre avis",
    Lang.ar: "شاركنا رأيك",
    Lang.ru: "Оставьте отзыв"
  },
};
