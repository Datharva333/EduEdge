class MockService {
  static final List<Map<String, dynamic>> subjects = [
    {'id': 'science', 'name': 'Science', 'icon': '🔬', 'color': '0xFF5C6BC0'},
    {'id': 'history', 'name': 'History', 'icon': '📖', 'color': '0xFF8D6E63'},
    {'id': 'english', 'name': 'English', 'icon': '📝', 'color': '0xFF26A69A'},
  ];

  static final List<Map<String, dynamic>> lessons = [
    // SCIENCE — Class 9
    {
      'id': '1',
      'title': 'Matter in Our Surroundings',
      'subject': 'Science',
      'class': '9',
      'icon': '⚗️',
      'content':
          'Matter is anything that has mass and occupies space. Matter exists in three states: solid, liquid, and gas. '
          'In solids, particles are tightly packed and have a fixed shape and volume. '
          'In liquids, particles are loosely packed and have a fixed volume but no fixed shape. '
          'In gases, particles are very far apart and have neither fixed shape nor volume. '
          'Matter can change from one state to another by absorbing or releasing heat energy. '
          'The process of conversion of solid to liquid is called melting, liquid to gas is called evaporation, '
          'and gas to liquid is called condensation. '
          'The temperature at which a solid melts is called its melting point, '
          'and the temperature at which a liquid boils is called its boiling point.',
    },
    {
      'id': '2',
      'title': 'Quadratic Equations',
      'subject': 'Mathematics',
      'class': '10',
    },
    {
      'id': '3',
      'title': 'Atoms and Molecules',
      'subject': 'Science',
      'class': '9',
      'icon': '⚛️',
      'content':
          'All matter is made up of tiny particles called atoms. '
          'An atom is the smallest particle of an element that can take part in a chemical reaction. '
          'Atoms are extremely small — one atom of hydrogen has a mass of 1.67 × 10⁻²⁴ grams. '
          'A molecule is formed when two or more atoms combine. '
          'Molecules of an element contain the same kind of atoms, like O2 and H2. '
          'Molecules of a compound contain different kinds of atoms, like H2O and CO2. '
          'The atomic mass of an element is the relative mass of its atom compared to the mass of a carbon-12 atom. '
          'Avogadro\'s number (6.022 × 10²³) is the number of atoms or molecules in one mole of a substance.',
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
          'All living organisms are made up of cells. Unicellular organisms have only one cell, like amoeba and bacteria. '
          'Multicellular organisms have many cells, like humans and plants. '
          'A cell has three main parts: the cell membrane, the cytoplasm, and the nucleus. '
          'The cell membrane controls what enters and leaves the cell. '
          'The nucleus contains DNA and controls all cell activities. '
          'Plant cells have a cell wall, chloroplasts, and a large vacuole, which animal cells do not have. '
          'The mitochondria is the powerhouse of the cell, producing energy through respiration.',
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
          'Velocity is the displacement per unit time and has both magnitude and direction. '
          'Acceleration is the rate of change of velocity. Acceleration = (Final velocity - Initial velocity) / Time. '
          'The three equations of motion are: v = u + at, s = ut + ½at², v² = u² + 2as, '
          'where u is initial velocity, v is final velocity, a is acceleration, s is displacement, and t is time.',
    },
    {
      'id': '6',
      'title': 'Force and Laws of Motion',
      'subject': 'Science',
      'class': '9',
      'icon': '⚡',
      'content':
          'Force is a push or pull that changes or tends to change the state of rest or motion of an object. '
          'Newton\'s First Law: An object remains at rest or in uniform motion unless acted upon by an external force. This is also called the Law of Inertia. '
          'Newton\'s Second Law: The force acting on an object is equal to the product of its mass and acceleration. F = ma. '
          'Newton\'s Third Law: For every action, there is an equal and opposite reaction. '
          'Momentum is the product of mass and velocity. p = mv. '
          'The Law of Conservation of Momentum states that the total momentum of a system remains constant if no external force acts on it.',
    },
    // HISTORY — Class 9-10
    {
      'id': '7',
      'title': 'The French Revolution',
      'subject': 'History',
      'class': '9',
      'icon': '🏰',
      'content':
          'The French Revolution began in 1789 and fundamentally transformed France and influenced the world. '
          'France in the 18th century was divided into three estates. The First Estate was the clergy, '
          'the Second Estate was the nobility, and the Third Estate included everyone else — peasants, merchants, and workers. '
          'The Third Estate paid heavy taxes while the privileged estates paid none. '
          'The ideas of liberty, equality, and fraternity inspired the revolutionaries. '
          'On July 14, 1789, the Bastille prison was stormed, marking the symbolic start of the Revolution. '
          'The monarchy was abolished and King Louis XVI was executed in 1793. '
          'The Revolution led to the Declaration of the Rights of Man, establishing principles of freedom and equality. '
          'Napoleon Bonaparte rose to power after the Revolution, spreading revolutionary ideas across Europe.',
    },
    {
      'id': '8',
      'title': 'Nazism and the Rise of Hitler',
      'subject': 'History',
      'class': '9',
      'icon': '📜',
      'content':
          'Adolf Hitler and the Nazi Party came to power in Germany in 1933. '
          'Germany was humiliated after World War I by the Treaty of Versailles, which imposed heavy reparations and territorial losses. '
          'The Great Depression of 1929 caused massive unemployment and economic hardship in Germany. '
          'Hitler exploited this crisis, promising to restore Germany\'s glory and blaming Jews and other minorities for Germany\'s problems. '
          'The Nazi ideology was based on extreme nationalism, racism, and anti-Semitism. '
          'Hitler became Chancellor in 1933 and quickly established a totalitarian dictatorship. '
          'The Holocaust was the systematic genocide of six million Jews and millions of others by the Nazi regime. '
          'World War II began when Germany invaded Poland in 1939. Germany was defeated in 1945.',
    },
    {
      'id': '9',
      'title': 'Nationalism in India',
      'subject': 'History',
      'class': '10',
      'icon': '🇮🇳',
      'content':
          'Indian nationalism emerged as a response to British colonial rule. '
          'The Indian National Congress was founded in 1885 and became the leading organization for independence. '
          'Mahatma Gandhi returned to India in 1915 and transformed the independence movement into a mass movement. '
          'The Non-Cooperation Movement (1920-22) called on Indians to boycott British goods, schools, and courts. '
          'The Civil Disobedience Movement began in 1930 with Gandhi\'s famous Dandi March, where he walked 240 miles to make salt from seawater to protest the salt tax. '
          'The Quit India Movement of 1942 demanded immediate independence from British rule. '
          'India finally gained independence on August 15, 1947. '
          'The partition of India and Pakistan accompanied independence, causing massive displacement and communal violence.',
    },
    {
      'id': '10',
      'title': 'The Age of Industrialisation',
      'subject': 'History',
      'class': '10',
      'icon': '🏭',
      'content':
          'The Industrial Revolution began in Britain in the 18th century and transformed the world. '
          'Before industrialisation, most goods were made by hand in homes or small workshops. '
          'The invention of the steam engine by James Watt in 1769 was a turning point, powering factories, ships, and railways. '
          'Cotton textile industries were among the first to industrialise, using machines like the spinning jenny and power loom. '
          'Industrialisation created new social classes — the industrial middle class (factory owners) and the industrial working class. '
          'Workers, including women and children, worked long hours in dangerous conditions for low wages. '
          'In India, industrialisation under British rule meant Indian textile industries were destroyed as cheap British machine-made goods flooded the market. '
          'Indian industries like Tata Steel began emerging in the late 19th century despite British policies.',
    },
    // ENGLISH — Class 9-10
    {
      'id': '11',
      'title': 'The Fun They Had — Story Analysis',
      'subject': 'English',
      'class': '9',
      'icon': '📚',
      'content':
          'The Fun They Had is a science fiction story by Isaac Asimov, set in the year 2157. '
          'The story is about two children, Margie and Tommy, who live in a future where children are taught by mechanical teachers at home. '
          'Tommy finds a real printed book — something extraordinary in their time — and they read about the old kind of school. '
          'In the old schools, children sat together in a building, had a human teacher, and learned the same things. '
          'Margie had been struggling with geography and her mechanical teacher had been adjusted many times. '
          'The story contrasts the cold, isolated learning of the future with the warm, social learning of the past. '
          'Margie thinks about the fun the children of the past must have had — going to school together, helping each other, laughing together. '
          'The story raises questions about technology in education and the value of human connection in learning.',
    },
    {
      'id': '12',
      'title': 'Grammar — Tenses',
      'subject': 'English',
      'class': '9',
      'icon': '✏️',
      'content':
          'Tenses are forms of verbs that show the time of an action or state. '
          'There are three main tenses: Present, Past, and Future. Each has four aspects: Simple, Continuous, Perfect, and Perfect Continuous. '
          'Simple Present: Used for habitual actions and general truths. Example: The sun rises in the east. '
          'Present Continuous: Used for actions happening right now. Example: She is reading a book. '
          'Present Perfect: Used for actions completed in the recent past with present relevance. Example: I have finished my homework. '
          'Simple Past: Used for completed actions in the past. Example: He went to school yesterday. '
          'Past Continuous: Used for actions that were ongoing in the past. Example: They were playing cricket when it rained. '
          'Simple Future: Used for actions that will happen in the future. Example: I will visit Delhi next week. '
          'The key is to use the correct tense to clearly communicate when an action takes place.',
    },
    {
      'id': '13',
      'title': 'A Letter to God — Story Analysis',
      'subject': 'English',
      'class': '10',
      'icon': '✉️',
      'content':
          'A Letter to God is a short story by G.L. Fuentes, translated from Spanish. '
          'The story is about Lencho, a poor farmer who lives with his family in a small house on a hill. '
          'Lencho was expecting a good harvest but a hailstorm destroyed all his crops, leaving his family with nothing to eat. '
          'Lencho had firm faith in God and believed God would help him. He wrote a letter to God asking for 100 pesos. '
          'The postmaster found the letter amusing but was also moved by Lencho\'s faith. '
          'He collected money from his employees and sent 70 pesos to Lencho in God\'s name. '
          'When Lencho received the money, he was not satisfied — he wrote another letter to God saying the post office employees had stolen 30 pesos. '
          'The story is ironic and explores themes of faith, innocence, and the contrast between Lencho\'s deep faith and his suspicion of honest people.',
    },
  ];

  static List<Map<String, dynamic>> getLessonsBySubject(String subject) {
    return lessons.where((l) => l['subject'] == subject).toList();
  }

  static List<Map<String, dynamic>> getLessonsByClass(String classNum) {
    return lessons.where((l) => l['class'] == classNum).toList();
  }
}
