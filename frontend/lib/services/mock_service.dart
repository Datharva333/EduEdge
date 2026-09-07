class MockService {
  static final List<Map<String, dynamic>> subjects = [
    {'id': 'maths', 'name': 'Mathematics', 'icon': '📐', 'color': '0xFF5C6BC0'},
    {'id': 'science', 'name': 'Science', 'icon': '⚗️', 'color': '0xFF26A69A'},
    {'id': 'history', 'name': 'History', 'icon': '📖', 'color': '0xFF8D6E63'},
    {'id': 'english', 'name': 'English', 'icon': '✏️', 'color': '0xFF78909C'},
  ];

  static final List<Map<String, dynamic>> lessons = [
    {
      'id': '1',
      'title': 'Quadratic Equations',
      'subject': 'Mathematics',
      'class': '10',
      'icon': '📐',
      'content':
          'A quadratic equation is a polynomial equation of degree 2, which means the highest power of the variable is 2. '
          'The standard form of a quadratic equation is ax² + bx + c = 0, where a, b, and c are real numbers and a is not equal to 0. '
          'If a were equal to 0, the equation would become a linear equation instead of a quadratic equation. '
          'In the standard form, a is called the leading coefficient, b is the linear coefficient, and c is the constant term. '
          'Quadratic equations can be solved using factorisation, completing the square, or the quadratic formula. '
          'The quadratic formula is x = (-b ± √(b² - 4ac)) / (2a). '
          'The expression b² - 4ac is called the discriminant. '
          'The discriminant tells us the nature of the roots of the quadratic equation. '
          'If the discriminant is greater than 0, the equation has two distinct real roots. '
          'If the discriminant is equal to 0, the equation has one repeated real root. '
          'If the discriminant is less than 0, the equation has two complex roots. '
          'The graph associated with a quadratic equation is a parabola. '
          'If the leading coefficient a is positive, the parabola opens upward, while if a is negative, the parabola opens downward. '
          'Quadratic equations are used in mathematics, geometry, physics, and many real-world problems involving areas, trajectories, and optimisation.',
    },
    {
      'id': '2',
      'title': 'Is Matter Around Us Pure?',
      'subject': 'Science',
      'class': '9',
      'icon': '⚗️',
      'content':
          'Matter may be classified as a pure substance or a mixture. '
          'A mixture contains two or more substances physically combined in any proportion, and its components retain their individual properties. '
          'Mixtures may be homogeneous or heterogeneous. '
          'A homogeneous mixture has a uniform composition throughout, while a heterogeneous mixture has a non-uniform composition. '
          'A solution is a homogeneous mixture containing a solute and a solvent. '
          'The solute is the substance that dissolves, while the solvent is the substance that dissolves the solute. '
          'Solutions, suspensions, and colloids differ in particle size, stability, filtration behaviour, and their interaction with light. '
          'A true solution does not show the Tyndall effect because its particles are too small to scatter light. '
          'Suspensions contain large particles that may settle down when left undisturbed and can usually be separated by filtration. '
          'Colloids have particles that are smaller than suspension particles but large enough to scatter light. '
          'The scattering of light by colloidal or suspension particles is called the Tyndall effect. '
          'Pure substances are classified as elements or compounds. '
          'An element contains only one type of atom, while a compound contains two or more elements chemically combined in a fixed proportion.',
    },
    {
      'id': '3',
      'title': 'Grammar — Tenses',
      'subject': 'English',
      'class': '9',
      'icon': '✏️',
      'content':
          'Tenses are forms of verbs that show the time of an action or state. '
          'There are three main tenses: Present, Past, and Future. '
          'Each main tense can appear in different forms such as Simple, Continuous, Perfect, and Perfect Continuous. '
          'Simple Present is used for habits, routines, and general truths. '
          'For example, "The sun rises in the east." '
          'Present Continuous is used for actions happening at the present moment. '
          'For example, "She is reading a book." '
          'Present Perfect is used for actions completed in the recent past that still have importance in the present. '
          'For example, "I have finished my homework." '
          'Simple Past is used for completed actions that happened in the past. '
          'For example, "He went to school yesterday." '
          'Past Continuous describes an action that was continuing at a particular time in the past. '
          'For example, "They were playing cricket when it rained." '
          'Simple Future is used for actions that will happen in the future. '
          'For example, "I will visit Delhi next week." '
          'Using the correct tense helps clearly communicate when an action takes place.',
    },
    {
      'id': '4',
      'title': 'The Fundamental Unit of Life',
      'subject': 'Science',
      'class': '9',
      'icon': '🦠',
      'content':
          'The cell is the basic structural and functional unit of life. '
          'Robert Hooke discovered cells in 1665 when he observed cork under a microscope. '
          'All living organisms are made up of cells. '
          'Unicellular organisms have only one cell, such as amoeba and bacteria. '
          'Multicellular organisms have many cells, such as humans and plants. '
          'A cell has three main parts: the cell membrane, the cytoplasm, and the nucleus. '
          'The cell membrane controls what enters and leaves the cell. '
          'The nucleus contains DNA and controls cell activities. '
          'Plant cells have a cell wall, chloroplasts, and a large vacuole, which animal cells do not have. '
          'Mitochondria release energy through respiration and are often called the powerhouse of the cell.',
    },
    {
      'id': '5',
      'title': 'Motion',
      'subject': 'Science',
      'class': '9',
      'icon': '🏃',
      'content':
          'Motion is the change in position of an object with respect to time and its surroundings. '
          'Distance is the total path length covered by an object. '
          'Displacement is the shortest distance between the initial and final positions of an object. '
          'Speed is the distance covered per unit time. Speed = Distance / Time. '
          'Velocity is displacement per unit time and has both magnitude and direction. '
          'Acceleration is the rate of change of velocity. '
          'Acceleration = (Final velocity - Initial velocity) / Time. '
          'The three equations of motion are v = u + at, s = ut + ½at², and v² = u² + 2as. '
          'Here u is initial velocity, v is final velocity, a is acceleration, s is displacement, and t is time.',
    },
    {
      'id': '6',
      'title': 'Force and Laws of Motion',
      'subject': 'Science',
      'class': '9',
      'icon': '⚡',
      'content':
          'Force is a push or pull that changes or tends to change the state of rest or motion of an object. '
          'Newton\'s First Law states that an object remains at rest or in uniform motion unless acted upon by an external force. '
          'This is also called the Law of Inertia. '
          'Newton\'s Second Law states that the force acting on an object is equal to the product of its mass and acceleration. F = ma. '
          'Newton\'s Third Law states that for every action, there is an equal and opposite reaction. '
          'Momentum is the product of mass and velocity. p = mv. '
          'The Law of Conservation of Momentum states that the total momentum of a system remains constant when no external force acts on it.',
    },
    {
      'id': '7',
      'title': 'The French Revolution',
      'subject': 'History',
      'class': '9',
      'icon': '🏰',
      'content':
          'The French Revolution began in 1789 and transformed France while influencing political movements across the world. '
          'France in the 18th century was divided into three estates. '
          'The First Estate consisted of the clergy, the Second Estate consisted of the nobility, and the Third Estate included peasants, merchants, workers, and other ordinary citizens. '
          'The Third Estate paid heavy taxes while the privileged estates enjoyed many exemptions. '
          'The ideas of liberty, equality, and fraternity inspired the revolutionaries. '
          'On July 14, 1789, the Bastille prison was stormed and became a symbol of the beginning of the Revolution. '
          'The monarchy was later abolished and King Louis XVI was executed in 1793. '
          'The Revolution led to the Declaration of the Rights of Man and Citizen, which promoted freedom and equality. '
          'Napoleon Bonaparte later rose to power and spread several revolutionary ideas across Europe.',
    },
    {
      'id': '8',
      'title': 'Nazism and the Rise of Hitler',
      'subject': 'History',
      'class': '9',
      'icon': '📜',
      'content':
          'Adolf Hitler and the Nazi Party came to power in Germany in 1933. '
          'Germany faced humiliation and economic difficulties after World War I and the Treaty of Versailles. '
          'The Great Depression of 1929 caused widespread unemployment and economic hardship. '
          'Hitler exploited the crisis by promising to restore Germany\'s power and by blaming Jews and other minorities for Germany\'s problems. '
          'Nazi ideology was based on extreme nationalism, racism, anti-Semitism, and dictatorship. '
          'Hitler became Chancellor in 1933 and quickly created a totalitarian state. '
          'The Holocaust was the systematic genocide of six million Jews and millions of other victims by the Nazi regime. '
          'World War II began when Germany invaded Poland in 1939, and Germany was defeated in 1945.',
    },
    {
      'id': '9',
      'title': 'Nationalism in India',
      'subject': 'History',
      'class': '10',
      'icon': '🇮🇳',
      'content':
          'Indian nationalism developed as a response to British colonial rule. '
          'The Indian National Congress was founded in 1885 and became an important organisation in the struggle for independence. '
          'Mahatma Gandhi returned to India in 1915 and helped transform the independence struggle into a mass movement. '
          'The Non-Cooperation Movement of 1920-22 encouraged Indians to boycott British goods, schools, and courts. '
          'The Civil Disobedience Movement began in 1930 and included Gandhi\'s Dandi March against the British salt tax. '
          'The Quit India Movement of 1942 demanded an end to British rule. '
          'India gained independence on August 15, 1947. '
          'Independence was accompanied by the partition of India and Pakistan, which caused large-scale displacement and communal violence.',
    },
    {
      'id': '10',
      'title': 'The Age of Industrialisation',
      'subject': 'History',
      'class': '10',
      'icon': '🏭',
      'content':
          'The Industrial Revolution began in Britain during the 18th century and transformed manufacturing and society. '
          'Before industrialisation, many goods were produced by hand in homes or small workshops. '
          'The development of steam power helped factories, ships, and railways expand rapidly. '
          'Cotton textile industries were among the first industries to use large-scale machinery such as the spinning jenny and power loom. '
          'Industrialisation created new social groups including factory owners and industrial workers. '
          'Workers, including women and children, often worked long hours in unsafe conditions for low wages. '
          'In colonial India, British machine-made textiles created major difficulties for traditional Indian textile producers. '
          'Indian industries such as Tata Steel later developed despite colonial economic policies.',
    },
    {
      'id': '11',
      'title': 'The Fun They Had — Story Analysis',
      'subject': 'English',
      'class': '9',
      'icon': '📚',
      'content':
          'The Fun They Had is a science fiction story by Isaac Asimov set in the year 2157. '
          'The story follows two children, Margie and Tommy, who are taught at home by mechanical teachers. '
          'Tommy discovers an old printed book describing schools from the past. '
          'In those schools, children studied together in a school building and were taught by human teachers. '
          'Margie has difficulty with geography and her mechanical teacher has to be adjusted. '
          'The story contrasts isolated technology-based education with the social experience of traditional schools. '
          'Margie begins imagining how much fun children in the past may have had learning together, helping one another, and sharing experiences. '
          'The story explores technology in education and the importance of human interaction in learning.',
    },
    {
      'id': '12',
      'title': 'Grammar — Tenses',
      'subject': 'English',
      'class': '9',
      'icon': '✏️',
      'content':
          'Tenses are forms of verbs that show the time of an action or state. '
          'There are three main tenses: Present, Past, and Future. '
          'Each tense can have Simple, Continuous, Perfect, and Perfect Continuous forms. '
          'Simple Present is used for habitual actions and general truths. Example: The sun rises in the east. '
          'Present Continuous is used for actions happening right now. Example: She is reading a book. '
          'Present Perfect is used for actions completed in the recent past that remain relevant to the present. Example: I have finished my homework. '
          'Simple Past is used for completed actions in the past. Example: He went to school yesterday. '
          'Past Continuous is used for actions that were ongoing in the past. Example: They were playing cricket when it rained. '
          'Simple Future is used for actions that will happen in the future. Example: I will visit Delhi next week. '
          'Correct use of tense helps clearly communicate when an action takes place.',
    },
    {
      'id': '13',
      'title': 'A Letter to God — Story Analysis',
      'subject': 'English',
      'class': '10',
      'icon': '✉️',
      'content':
          'A Letter to God is a short story by G.L. Fuentes. '
          'The story is about Lencho, a poor farmer who lives with his family in a small house on a hill. '
          'Lencho expects a good harvest, but a hailstorm destroys his crops and leaves his family without food. '
          'Because of his strong faith in God, Lencho writes a letter asking God for 100 pesos. '
          'The postmaster is moved by Lencho\'s faith and collects money from employees to help him. '
          'Lencho receives 70 pesos but believes the remaining money was stolen by postal employees. '
          'He writes another letter to God asking for the remaining money and warning God not to send it through the post office. '
          'The story uses irony and explores themes of faith, innocence, trust, and human kindness.',
    },
  ];

  static List<Map<String, dynamic>> getLessonsBySubject(String subject) {
    return lessons.where((lesson) => lesson['subject'] == subject).toList();
  }

  static List<Map<String, dynamic>> getLessonsByClass(String classNum) {
    return lessons.where((lesson) => lesson['class'] == classNum).toList();
  }
}
