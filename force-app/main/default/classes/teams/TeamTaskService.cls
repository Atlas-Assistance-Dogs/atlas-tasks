public class TeamTaskService {
    // Repositories
    TeamRepository teamRepo;
    RelationshipRepository relRepo;
    DogRepository dogRepo;
    TaskRepository taskRepo;
    PatRepository patRepo;
    // Users
    User admin;
    User clientManager;
    User clientSupportCoordinator;
    User tfManager;
    User trainerManager;
    // Constants
    private static final String STATUS_NOT_STARTED = 'Not Started';
    private static final String PRIORITY_NORMAL = 'Normal';
    private static final Integer DAYS_ONE_MONTH = 30;
    private static final Integer DAYS_FOUR_POINT_FIVE_MONTHS = 135;
    private static final Integer DAYS_FIVE_MONTHS = 150;
    private static final Integer DAYS_SIX_MONTHS = 180;
    private static final Integer DAYS_EIGHT_MONTHS = 240;
    private static final String SUBJECT_1MO_CLIENT = '1 mo in-training checkin due';
    private static final String SUBJECT_1MO_TF = '1 mo in-training checkin due for TF';
    private static final String SUBJECT_4_5MO = 'Check on client\'s courses and give Molly status';
    private static final String SUBJECT_5MO_CLIENT = '5 mo client in-training checkin due';
    private static final String SUBJECT_5MO_TF = '5 mo in-training checkin due for TF';
    private static final String SUBJECT_6MO = 'Check on dog spay/neuter status';
    private static final String SUBJECT_8MO_CLIENT = '8 mo client in-training checkin due';
    private static final String SUBJECT_8MO_TF = '8 mo in-training checkin due for TF';
    private static final String DESC_5MO_CLIENT = 'Check on practice PAT and class status';
    private static final String DESC_8MO_CLIENT = 'Confirm spay, see if need extension';
    public TeamTaskService() {
        teamRepo = new TeamRepository();
        relRepo = new RelationshipRepository();
        dogRepo = new DogRepository();
        taskRepo = new TaskRepository();
        patRepo = new PatRepository();
        getUsers();
    }

    void getUsers() {
        admin = taskRepo.getTaskUser('Administrator');
        clientSupportCoordinator = taskRepo.getTaskUser('Client Support Coordinator');
        clientManager = taskRepo.getTaskUser('Client Manager');
        tfManager = taskRepo.getTaskUser('TF Manager');
        trainerManager = taskRepo.getTaskUser('Trainer Manager');
    }

    @testVisible
    private TeamTaskService(TeamRepository teamRepo, RelationshipRepository relRepo, DogRepository dogRepo, TaskRepository taskRepo, PatRepository patRepo) {
        this.teamRepo = teamRepo;
        this.relRepo = relRepo;
        this.dogRepo = dogRepo;
        this.taskRepo = taskRepo;
        this.patRepo = patRepo;
        getUsers();
    }

    // Helper to construct a Task with defaults
    class TaskFactory {
        public atlas1__Team__c team { get;private  set; }

        Id ownerId;
        public TaskFactory(atlas1__Team__c team, User owner) {
            this.team = team;
            if (owner != null) {
                this.ownerId = owner.Id;
            }
        }

        public Task createTask(String subject, String description) {
            return new Task(
                Subject = subject, 
                WhatId = team.Id, 
                WhoId = team.atlas1__Client__c, 
                Description = description, 
                Status = STATUS_NOT_STARTED, 
                Priority = PRIORITY_NORMAL, 
                OwnerId = ownerId, 
                ActivityDate = Date.today()
            );
        }

        public Task createTask(String subject, String description, Id ownerId) {
            Task task = createTask(subject, description);
            task.OwnerId = ownerId;
            return task;
        }

    }

    // Create tasks related to teams
    public void handleTrainingStart(atlas1__Team__c team) {
        if (admin == null) {
            return;
        }
        Date today = Date.today();
        List<Task> tasks = new List<Task>();
        TaskFactory tf = new TaskFactory(team, admin);
        tasks.add(tf.createTask('Client entered training', 'Confirm returns forms, assign courses, add to office hours'));
        taskRepo.create(tasks);
    }

    // create the tasks related to team training
    public void createTrainingTasks() {
        List<atlas1__Team__c> teams = teamRepo.getByStatus('In Training');
        if (teams.isEmpty()) {
            return;
        }
        List<Task> tasks = new List<Task>();
        for (atlas1__Team__c team : teams) {
            if (team.atlas1__TrainingStartDate__c == null) {
                team.atlas1__TrainingStartDate__c = Date.today();
                teamRepo.modify(team);
                handleTrainingStart(team);
                continue;
            }
            tasks.addAll(teamTasks(team));
        }
        taskRepo.create(tasks);
    }

    // Create team training tasks for the admin and the client manager
    // returns a list of tasks
    private List<Task> teamTasks(atlas1__Team__c team) {
        List<Task> tasks = new List<Task>();
        Date today = Date.today();
        Integer length = team.atlas1__TrainingStartDate__c.daysBetween(today);
        TaskFactory tf = new TaskFactory(team, clientManager);

        switch  on length {
            when 30 {
                // 1 month
                tasks.addAll(createClientManagerTasks(tf, SUBJECT_1MO_CLIENT, null, SUBJECT_1MO_TF));
            }
            when 135 {
                // 4.5 months
                if (admin != null) {
                    tasks.add(tf.createTask(SUBJECT_4_5MO, null, admin.Id));
                }
            }
            when 150 {
                // 5 months
                tasks.addAll(createClientManagerTasks(tf, SUBJECT_5MO_CLIENT, DESC_5MO_CLIENT, SUBJECT_5MO_TF));
            }
            when 180 {
                // 6 months
                if (admin != null) {
                    atlas1__Dog__c dog = dogRepo.getById(team.atlas1__Dog__c);
                    if (dog != null && !dog.atlas1__SpayedNeutered__c) {
                        tasks.add(tf.createTask(SUBJECT_6MO, null, admin.Id));
                    }
                }
            }
            when 240 {
                // 8 months
                tasks.addAll(createClientManagerTasks(tf, SUBJECT_8MO_CLIENT, DESC_8MO_CLIENT, SUBJECT_8MO_TF));
            }
        }
        return tasks;
    }

    // create tasks for the client manager for the client and team facilitator
    // tasks are due immediately, and assigned to the client manager
    // return a list of tasks
    Task[] createClientManagerTasks(TaskFactory tf, String clientSubject, String clientDesc, String tfSubject) {
        List<Task> tasks = new List<Task>();
        List<npe4__Relationship__c> relationships = relRepo.getCurrentRelated(new Set<Id>{ tf.team.atlas1__Client__c }, 'Team Facilitator');
        Boolean hasTFs = relationships != null && !relationships.isEmpty();

        if (clientManager != null) {
            Task ctask = tf.createTask(clientSubject, clientDesc);
            tasks.add(ctask);
        }
        if (hasTFs && tfManager != null) {
            for (npe4__Relationship__c rel : relationships) {
                Task task = tf.createTask(tfSubject, null);
                task.WhoId = rel.npe4__RelatedContact__c;
                task.OwnerId = tfManager.Id;
                tasks.add(task);
            }
        }
        return tasks;
    }

    class PatException extends Exception {
    }

    // Create tasks related to teams
    public void handleCertificationStart(atlas1__Team__c team) {
        // Get the first PAT
        atlas1__PublicAccessTest__c pat = patRepo.getFirstPat(team.Id);
        if (pat == null) {
            throw new PatException('No initial passing PAT found for team ' + team.Name);
        }
        if (team.atlas1__InitialCertificationDate__c == null) {
            // this is called by a trigger, so don't need to update here
            team.atlas1__InitialCertificationDate__c = pat.atlas1__DateCompleted__c;
        }
        if (clientSupportCoordinator == null) {
            return;
        }
        Task[] tasks = new Task[]{ new Task(
            Subject = 'begin client checkins', 
            WhatId = team.Id, 
            WhoId = team.atlas1__Client__c, 
            Status = 'Not Started', 
            Priority = 'Normal', 
            OwnerId = clientSupportCoordinator.Id, 
            ActivityDate = Date.today().addMonths(1)
        ) };
        taskRepo.create(tasks);
    }

    private static final String SUBJECT_CERT_FIRST_REMINDER = 'Client 1st recert due in 3 mo';
    private static final String SUBJECT_CERT_REMINDER = 'Client recert due in 3 mo';
    private static final String DESC_CERT_FIRST_REMINDER = 'Checkin and schedule PAT';
    private static final String DESC_CERT_REMINDER = 'Check vet paperwork, inform Molly';
    public void createCertificationTasks() {
        if (clientManager == null) {
            return;
        }
        List<atlas1__Team__c> teams = teamRepo.getByStatus('Certified');

        Date today = Date.today();
        List<Task> tasks = new List<Task>();
        for (atlas1__Team__c team : teams) {
            Integer length = today.daysBetween(team.atlas1__PatValidUntil__c);
            // if PAT expiration is within 90 days, and there are no existing tasks for this client and subject
            Task[] matching = taskRepo.getMatchingTasks(team.atlas1__Client__c, '%recert due in 3 mo%');
            if (length <= 90 && matching.isEmpty()) {
                if (team.atlas1__InitialCertificationDate__c == null || team.atlas1__InitialCertificationDate__c.daysBetween(today) < 365) {
                    tasks.add(new Task(
                        Subject = SUBJECT_CERT_FIRST_REMINDER, 
                        Description = DESC_CERT_FIRST_REMINDER, 
                        WhatId = team.Id, 
                        WhoId = team.atlas1__Client__c, 
                        Status = 'Not Started', 
                        Priority = 'Normal', 
                        OwnerId = clientManager.Id, 
                        ActivityDate = Date.today()
                    ));
                } else if (admin != null) {
                    tasks.add(new Task(
                        Subject = SUBJECT_CERT_REMINDER, 
                        Description = DESC_CERT_REMINDER, 
                        WhatId = team.Id, 
                        WhoId = team.atlas1__Client__c, 
                        Status = 'Not Started', 
                        Priority = 'Normal', 
                        OwnerId = admin.Id, 
                        ActivityDate = Date.today()
                    ));

                }
            }
        }
        taskRepo.create(tasks);
    }

}