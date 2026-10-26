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
  "Sign in": {
    Lang.fr: "Se connecter",
    Lang.ar: "تسجيل الدخول",
    Lang.ru: "Войти"
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
  "Ambulance transfers, accessible vehicles, free buses and airport pickups for Koru Hospital patients and visitors.":
      {
    Lang.fr:
        "Transferts en ambulance, véhicules adaptés, bus gratuits et accueil à l'aéroport pour les patients et visiteurs de l'hôpital Koru.",
    Lang.ar:
        "نقل بالإسعاف، ومركبات مجهزة لذوي الإعاقة، وحافلات مجانية، واستقبال من المطار لمرضى وزوار مستشفى كورو.",
    Lang.ru:
        "Перевозка на скорой, автомобили для людей с ограниченной подвижностью, бесплатные автобусы и встреча в аэропорту для пациентов и посетителей больницы Koru."
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

  // Homepage: free buses, comments, branches, drivers.
  "Next free buses": {
    Lang.fr: "Prochains bus gratuits",
    Lang.ar: "الحافلات المجانية القادمة",
    Lang.ru: "Ближайшие бесплатные автобусы"
  },
  "Free for everyone visiting Koru Hospital. Look for the blue bus sign at the main entrance.":
      {
    Lang.fr:
        "Gratuit pour tous les visiteurs de l'hôpital Koru. Repérez le panneau bleu « Bus » à l'entrée principale.",
    Lang.ar:
        "مجانية لكل زوار مستشفى كورو. ابحث عن لافتة الحافلة الزرقاء عند المدخل الرئيسي.",
    Lang.ru:
        "Бесплатно для всех посетителей больницы Koru. Ищите синий знак автобуса у главного входа."
  },
  "Every [XX] min": {
    Lang.fr: "Toutes les [XX] min",
    Lang.ar: "كل [XX] دقيقة",
    Lang.ru: "Каждые [XX] мин"
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
  "Free bus": {
    Lang.fr: "Bus gratuit",
    Lang.ar: "حافلة مجانية",
    Lang.ru: "Бесплатный автобус"
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
};
