/**
 * TeamTaskService
 *
 * Responsible for creating and managing team-related Tasks used across
 * the application. This class encapsulates interactions with team,
 * relationship, dog, task and PAT repositories and exposes higher-level
 * operations for scheduling and updating tasks for teams. Added
 * documentation to satisfy Documentation-ApexDoc rule.
 */
@SuppressWarnings('ApexCognitiveComplexity')
public class TeamTaskService {
	private static final String TEAM_ACCEPTED = 'Team newly accepted';
    private static final String STARTED_TRAINING = 'Client entered training';
    private static final String NEWLY_CERTIFIED = 'Team newly certified';
    // Repositories
    TeamRepository teamRepo;
    RelationshipRepository relRepo;
    DogRepository dogRepo;
    TaskRepository taskRepo;
    PatRepository patRepo;
    // Users
    User admin;
    User adminAssistant;
    User clientManager;
    User clientSupportCoordinator;
    User inventoryAdmin;
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
    /**
     * Initializes the TeamTaskService with required repositories and users.
     */
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
        adminAssistant = taskRepo.getTaskUser('Admin Assistant');
        inventoryAdmin = taskRepo.getTaskUser('Inventory Admin');
        clientSupportCoordinator = taskRepo.getTaskUser('Client Support Coordinator');
        clientManager = taskRepo.getTaskUser('Client Manager');
        inventoryAdmin = taskRepo.getTaskUser('Inventory Admin');
        tfManager = taskRepo.getTaskUser('TF Manager');
        trainerManager = taskRepo.getTaskUser('Trainer Manager');
    }

    /**
     * Initializes the TeamTaskService with required repositories and users.
     * @param teamRepo Team repository.
     * @param relRepo Relationship repository.
     * @param dogRepo Dog repository.
     * @param taskRepo Task repository.
     * @param patRepo PAT repositoryƒ.
     */
    @SuppressWarnings('ExcessiveParameterList')
    @testVisible
    private TeamTaskService(TeamRepository teamRepo, RelationshipRepository relRepo, DogRepository dogRepo, TaskRepository taskRepo, PatRepository patRepo) {
        this.teamRepo = teamRepo;
        this.relRepo = relRepo;
        this.dogRepo = dogRepo;
        this.taskRepo = taskRepo;
        this.patRepo = patRepo;
        getUsers();
    }

    /** Helper to construct a Task with defaults. */
    class TaskFactory {
        /** The team record. */
        public atlas1__Team__c team { get;private  set; }

        Id ownerId;
        /**
         * Construct a TaskFactory for a team and owner.
         * @param team Team record.
         * @param owner Task owner.
         */
        public TaskFactory(atlas1__Team__c team, User owner) {
            this.team = team;
            if (owner != null) {
                this.ownerId = owner.Id;
            }
        }

        /**
         * Create a Task with defaults.
         * @param subject Task subject.
         * @param description Task description.
         * @return Task instance.
         */
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

        /**
         * Create a Task with defaults and a specific owner.
         * @param subject Task subject.
         * @param description Task description.
         * @param ownerId Task owner.
         * @return Task instance.
         */
        public Task createTask(String subject, String description, Id ownerId) {
            Task task = createTask(subject, description);
            task.OwnerId = ownerId;
            return task;
        }

    }

    /**
     * @description Create tasks related to teams that have just enterred training.  Intended to be called by the Team trigger
     * @param team The name of the team enterring training.
     * @example service.T(team);
     */
    public void handleTrainingStart(atlas1__Team__c team) {
        Date today = Date.today();
        List<Task> tasks = new List<Task>();
        TaskFactory tf;
        if (admin != null) {
            tf = new TaskFactory(team, admin);
            tasks.add(tf.createTask('Confirm returns forms', STARTED_TRAINING));
            tasks.add(tf.createTask('Assign courses', STARTED_TRAINING));
            tasks.add(tf.createTask('Add to office hours', STARTED_TRAINING));
            tasks.add(tf.createTask('Add training log to google drive', STARTED_TRAINING));
        }
        if (inventoryAdmin != null) {
            tf = new TaskFactory(team, inventoryAdmin);
            tasks.add(tf.createTask('Send client welcome packet', TEAM_ACCEPTED));
            tasks.add(tf.createTask('Send TF in-training vest and first aid kit', TEAM_ACCEPTED));
        }
        if (tasks.isEmpty()) {
            return;
        }
        taskRepo.create(tasks);
    }

    /**
     * Creates tasks related to teams that are in training status.
     */
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

    /**
     * Creates tasks for the client manager for the client and team facilitator
     *tasks are due immediately, and assigned to the client manager
     * return a list of tasks
     * @param tf the task factory
     * @param clientSubject the subject for the client task
     * @param clientDesc the description for the client task
     * @param tfSubject the subject for the team facilitator task
     * @return an array of tasks
     */
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

    /**
     * Create tasks related to teams when certification starts.
     * @param team the Team record for which certification is starting
     */
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
        TaskFactory tf;
        List<Task> tasks = new List<Task>();
        if (clientSupportCoordinator != null) {
            tf = new TaskFactory(team, clientSupportCoordinator);
            Task task = tf.createTask('Begin client checkins', 'Schedule checkins every 3 months, inform Molly');
            task.ActivityDate = Date.today().addMonths(1);
            tasks.add(task);
        }
        if (admin != null) {
            tf = new TaskFactory(team, admin);
            tasks.add(tf.createTask('Assign fitness course', NEWLY_CERTIFIED));
            tasks.add(tf.createTask('Mark assigned program complete', NEWLY_CERTIFIED));
            tasks.add(tf.createTask('Save grade report', NEWLY_CERTIFIED));
        }
        if (adminAssistant != null) {
            tf = new TaskFactory(team, adminAssistant);
            tasks.add(tf.createTask('Cleanup google drive', NEWLY_CERTIFIED));
        }
        if (tasks.isEmpty()) {
            return;
        }
        taskRepo.create(tasks);
    }

    private static final String SUBJECT_CERT_FIRST_REMINDER = 'Client 1st recert due in 3 mo';
    private static final String SUBJECT_CERT_REMINDER = 'Client recert due in 3 mo';
    private static final String DESC_CERT_FIRST_REMINDER = 'Checkin and schedule PAT';
    private static final String DESC_CERT_REMINDER = 'Check vet paperwork, inform Molly';
    /**
     * Creates certification reminder tasks for teams with PAT expiration within 90 days.
     */
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

    // run daily to create admin tasks related to active dogs
    public void createDogTasks() {
        if (admin == null) {
            return;
        }
        Date today = Date.today();
        List<atlas1__Team__c> teams = teamRepo.getActiveDogs();
        if (teams == null || teams.isEmpty()) {
            return;
        }
        List<Task> tasks = new List<Task>();
        for (atlas1__Team__c team : teams) {
            if (team.atlas1__Dog__r == null) {
                continue; // this shouldn't happen, but checking just to be safe
            }
            atlas1__Dog__c dog = team.atlas1__Dog__r;
            if ((dog.atlas1__VaccineDueRabies__c != null && today == dog.atlas1__VaccineDueRabies__c) || (dog.atlas1__PhysicalExamDue__c != null && today == dog.atlas1__PhysicalExamDue__c) || (dog.atlas1__VaccineDueDA2PP__c != null && today == dog.atlas1__VaccineDueDA2PP__c)) {
                Task[] matching = taskRepo.getMatchingTasks(team.atlas1__Client__c, '%veterinary health records%');
                if (matching.isEmpty()) {
                    tasks.add(new Task(
                        WhatId = team.Id, 
                        WhoId = team.atlas1__Client__c, 
                        OwnerId = admin.Id, 
                        Subject = String.format('One or more veterinary health records is now expired for dog: {0} of team: {1}. Reach out to client', new Object[]{ dog.Name, team.Name }), 
                        Status = 'Not Started', 
                        Priority = 'Normal', 
                        ActivityDate = today
                    ));
                }
            }
        }
        taskRepo.create(tasks);
    }

}