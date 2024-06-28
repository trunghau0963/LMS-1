﻿IF OBJECT_ID('[dbo].[InsertCourseCategory]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[InsertCourseCategory];
GO

CREATE PROCEDURE InsertCourseCategory
AS
BEGIN
    DECLARE @courseId INT;
    DECLARE @categoryId INT;
    
    DECLARE course_cursor CURSOR FOR
    SELECT id FROM dbo.course;
    
    OPEN course_cursor;

    FETCH NEXT FROM course_cursor INTO @courseId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @categoryId = (SELECT TOP 1 id FROM dbo.category ORDER BY NEWID());
        
        INSERT INTO dbo.courseCategory (courseId, categoryId)
        VALUES (@courseId, @categoryId);
        
        FETCH NEXT FROM course_cursor INTO @courseId;
    END
    
    CLOSE course_cursor;
    DEALLOCATE course_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseDescriptionDetail]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseDescriptionDetail];
GO
CREATE PROCEDURE RandomizeCourseDescriptionDetail
AS
BEGIN
    DECLARE @courseId INT;
    DECLARE @content NVARCHAR(128);
    DECLARE @type VARCHAR(16);

    DECLARE course_cursor CURSOR FOR
    SELECT id, subtitle FROM dbo.course;
    
    OPEN course_cursor;

    FETCH NEXT FROM course_cursor INTO @courseId, @content;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @type = (SELECT TOP 1 type FROM (VALUES ('PREREQUISITE'), ('OBJECTIVE'), ('SKILL'), ('TARGET_USER'), ('LANGUAGE')) AS T(type) ORDER BY NEWID());
        INSERT INTO dbo.courseDescriptionDetail (courseId, content, type)
        VALUES (@courseId, @content, @type);
        FETCH NEXT FROM course_cursor INTO @courseId, @content;
    END
    
    CLOSE course_cursor;
    DEALLOCATE course_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeOwnedCourse]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeOwnedCourse];
GO
CREATE PROCEDURE RandomizeOwnedCourse
AS
BEGIN
    DECLARE @courseId INT;
    DECLARE @ownerEmail VARCHAR(256);
    DECLARE @sharePercentage FLOAT;

    DECLARE course_cursor CURSOR FOR
    SELECT id FROM dbo.course;
    
    OPEN course_cursor;

    FETCH NEXT FROM course_cursor INTO @courseId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @ownerEmail = (SELECT TOP 1 email FROM dbo.lecturer ORDER BY NEWID());
        SET @sharePercentage = ROUND((RAND() * 100), 2);
        INSERT INTO dbo.ownedCourse (ownerEmail, courseId, sharePercentage)
        VALUES (@ownerEmail, @courseId, @sharePercentage);
        
        FETCH NEXT FROM course_cursor INTO @courseId;
    END
    
    CLOSE course_cursor;
    DEALLOCATE course_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseAnnouncement]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseAnnouncement];
GO
CREATE PROCEDURE RandomizeCourseAnnouncement
AS
BEGIN
    DECLARE @senderEmail VARCHAR(256);
    DECLARE @courseId INT;
    DECLARE @createdAt DATE;
    DECLARE @title NVARCHAR(64);
    DECLARE @content NVARCHAR(512);
    DECLARE @subtitle NVARCHAR(128);

    DECLARE ownedCourse_cursor CURSOR FOR
    SELECT ownerEmail, courseId FROM dbo.ownedCourse;
    
    OPEN ownedCourse_cursor;
    FETCH NEXT FROM ownedCourse_cursor INTO @senderEmail, @courseId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @subtitle = subtitle FROM dbo.course WHERE id = @courseId;
		SELECT @createdAt = createdAt FROM dbo.course WHERE id = @courseId;
        SET @title = N'Thông báo';
        SET @content = N'Chào mừng đến với lớp ' + @subtitle;
        INSERT INTO dbo.courseAnnouncement (senderEmail, courseId, createdAt, title, content)
        VALUES (@senderEmail, @courseId, @createdAt, @title, @content);
        
        FETCH NEXT FROM ownedCourse_cursor INTO @senderEmail, @courseId;
    END
    
    CLOSE ownedCourse_cursor;
    DEALLOCATE ownedCourse_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeEnrolledCourse]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeEnrolledCourse];
GO
CREATE PROCEDURE RandomizeEnrolledCourse
AS
BEGIN
    DECLARE @learnerEmail VARCHAR(256);
    DECLARE @courseId INT;
    DECLARE @status CHAR(1);
    DECLARE learner_cursor CURSOR FOR
    SELECT email FROM dbo.learner;
    
    OPEN learner_cursor;
    FETCH NEXT FROM learner_cursor INTO @learnerEmail;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @courseId = (SELECT TOP 1 id FROM dbo.course ORDER BY NEWID());
        SET @status = (SELECT TOP 1 status FROM (VALUES ('B'), ('L'), ('F')) AS T(status) ORDER BY NEWID());
        INSERT INTO dbo.enrolledCourse (learnerEmail, courseId, status)
        VALUES (@learnerEmail, @courseId, @status);
        
        FETCH NEXT FROM learner_cursor INTO @learnerEmail;
    END
    
    CLOSE learner_cursor;
    DEALLOCATE learner_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseReview]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseReview];
GO
CREATE PROCEDURE RandomizeCourseReview
AS
BEGIN
    DECLARE @learnerEmail VARCHAR(256);
    DECLARE @courseId INT;
    DECLARE @courseCreatedAt DATE;
    DECLARE @reviewCreatedAt DATETIME;
    DECLARE @rating TINYINT;
    DECLARE @content NVARCHAR(512);
    DECLARE @subtitle NVARCHAR(128);
    DECLARE @reviewDays INT;
    DECLARE enrolledCourse_cursor CURSOR FOR
    SELECT learnerEmail, courseId FROM dbo.enrolledCourse;
    
    OPEN enrolledCourse_cursor;
    FETCH NEXT FROM enrolledCourse_cursor INTO @learnerEmail, @courseId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @subtitle = subtitle FROM dbo.course WHERE id = @courseId;
        SELECT @courseCreatedAt = createdAt FROM dbo.course WHERE id = @courseId;
        SET @reviewDays = DATEDIFF(DAY, @courseCreatedAt, GETDATE());
        SET @reviewCreatedAt = DATEADD(DAY, 1 + (RAND() * (@reviewDays - 1)), @courseCreatedAt);
        SET @rating = (SELECT FLOOR(RAND() * 5) + 1);
        SET @content = CASE 
                          WHEN @rating = 5 THEN @subtitle + N' bài học rất hay'
                          WHEN @rating BETWEEN 2 AND 4 THEN @subtitle + N' bài học ổn'
                          WHEN @rating = 1 THEN @subtitle + N' bài học rất tệ'
                       END;
        INSERT INTO dbo.courseReview (learnerEmail, courseId, createdAt, rating, content)
        VALUES (@learnerEmail, @courseId, @reviewCreatedAt, @rating, @content);
        
        FETCH NEXT FROM enrolledCourse_cursor INTO @learnerEmail, @courseId;
    END
    
    CLOSE enrolledCourse_cursor;
    DEALLOCATE enrolledCourse_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseSection]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseSection];
GO
CREATE PROCEDURE RandomizeCourseSection
AS
BEGIN
    DECLARE @id INT;
    DECLARE @courseId INT;
    DECLARE @nextCourseSectionId INT;
    DECLARE @title NVARCHAR(64);
    DECLARE @description NVARCHAR(512);
    DECLARE @similarId INT;
    DECLARE @keyword NVARCHAR(128);
    DECLARE @keyword_table TABLE (keyword NVARCHAR(128));
    DECLARE course_cursor CURSOR FOR
    SELECT id, title, description FROM dbo.course;

    OPEN course_cursor;
    FETCH NEXT FROM course_cursor INTO @courseId, @title, @description;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DELETE FROM @keyword_table;

        INSERT INTO @keyword_table (keyword)
        SELECT DISTINCT value FROM STRING_SPLIT(@title, ' ');

        DECLARE keyword_cursor CURSOR FOR
        SELECT keyword FROM @keyword_table;

        OPEN keyword_cursor;
        FETCH NEXT FROM keyword_cursor INTO @keyword;

        SET @id = (SELECT COALESCE(MAX(id), 0) + 1 FROM dbo.courseSection);
        INSERT INTO dbo.courseSection (id, courseId, title, description)
        VALUES (@id, @courseId, @title, @description);

        SELECT TOP 1 @similarId = id
        FROM dbo.courseSection
        WHERE title LIKE '%' + @keyword + '%'
          AND id <> @id
        ORDER BY NEWID();

        UPDATE dbo.courseSection
        SET nextCourseSectionId = CASE WHEN @similarId IS NULL THEN NULL ELSE @similarId END
        WHERE id = @id;

        CLOSE keyword_cursor;
        DEALLOCATE keyword_cursor;

        FETCH NEXT FROM course_cursor INTO @courseId, @title, @description;
    END;

    CLOSE course_cursor;
    DEALLOCATE course_cursor;
END;
GO


IF OBJECT_ID('[dbo].[RandomizeCourseLesson]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseLesson];
GO

CREATE PROCEDURE RandomizeCourseLesson
AS
BEGIN
    DECLARE @id INT;
    DECLARE @courseId INT;
    DECLARE @isFree BIT;
    DECLARE @durationInMinutes TINYINT;

    DECLARE course_cursor CURSOR FOR
    SELECT cs.id, cs.courseId
    FROM dbo.courseSection cs
    JOIN dbo.course c ON cs.courseId = c.id;

    OPEN course_cursor;
    FETCH NEXT FROM course_cursor INTO @id, @courseId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @isFree = CASE WHEN RAND() > 0.5 THEN 1 ELSE 0 END;
        SET @durationInMinutes = CAST(RAND() * 60 + 1 AS TINYINT);

        INSERT INTO dbo.courseLesson (id, courseId, isFree, durationInMinutes)
        VALUES (@id, @courseId, @isFree, @durationInMinutes);

        FETCH NEXT FROM course_cursor INTO @id, @courseId;
    END;

    CLOSE course_cursor;
    DEALLOCATE course_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseExercise]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseExercise];
GO

CREATE PROCEDURE RandomizeCourseExercise
AS
BEGIN
    DECLARE @id INT;
    DECLARE @courseId INT;
    DECLARE course_section_cursor CURSOR FOR
    SELECT id, courseId
    FROM dbo.courseSection;

    OPEN course_section_cursor;
    FETCH NEXT FROM course_section_cursor INTO @id, @courseId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO dbo.courseExercise (id, courseId)
        VALUES (@id, @courseId);

        FETCH NEXT FROM course_section_cursor INTO @id, @courseId;
    END;

    CLOSE course_section_cursor;
    DEALLOCATE course_section_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseQuiz]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseQuiz];
GO

CREATE PROCEDURE RandomizeCourseQuiz
AS
BEGIN
    DECLARE @id INT;
    DECLARE @courseId INT;
    DECLARE @durationInMinutes TINYINT;
    DECLARE exercise_cursor CURSOR FOR
    SELECT id, courseId
    FROM dbo.courseExercise;

    OPEN exercise_cursor;
    FETCH NEXT FROM exercise_cursor INTO @id, @courseId;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @durationInMinutes = ABS(CHECKSUM(NEWID())) % 60 + 1;
        INSERT INTO dbo.courseQuiz (id, courseId, durationInMinutes)
        VALUES (@id, @courseId, @durationInMinutes);

        FETCH NEXT FROM exercise_cursor INTO @id, @courseId;
    END;

    CLOSE exercise_cursor;
    DEALLOCATE exercise_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseQuizQuestion]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseQuizQuestion];
GO

CREATE PROCEDURE RandomizeCourseQuizQuestion
AS
BEGIN
    DECLARE @id INT;
    DECLARE @courseQuizId INT;
    DECLARE @courseId INT;
    DECLARE @question NVARCHAR(512);
    DECLARE @correctAnswerIndex TINYINT;

    DECLARE @questionPool TABLE (question NVARCHAR(512));
    INSERT INTO @questionPool (question)
    VALUES
    ('What is the capital of France?'),
    ('Who wrote "To Kill a Mockingbird"?'),
    ('What is the powerhouse of the cell?'),
    ('What year did the Titanic sink?'),
    ('Who painted the Mona Lisa?');
    DECLARE quiz_cursor CURSOR FOR
    SELECT id, courseId
    FROM dbo.courseQuiz;

    OPEN quiz_cursor;
    FETCH NEXT FROM quiz_cursor INTO @courseQuizId, @courseId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @id = (SELECT COALESCE(MAX(id), 0) + 1 FROM dbo.courseQuizQuestion);
        SET @correctAnswerIndex = ABS(CHECKSUM(NEWID())) % 4;
        SELECT TOP 1 @question = question
        FROM @questionPool
        ORDER BY NEWID();
        INSERT INTO dbo.courseQuizQuestion (id, courseQuizId, courseId, question, correctAnswerIndex)
        VALUES (@id, @courseQuizId, @courseId, @question, @correctAnswerIndex);

        FETCH NEXT FROM quiz_cursor INTO @courseQuizId, @courseId;
    END;

    CLOSE quiz_cursor;
    DEALLOCATE quiz_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseQuizQuestionAnswer]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseQuizQuestionAnswer];
GO

CREATE PROCEDURE RandomizeCourseQuizQuestionAnswer
AS
BEGIN
    DECLARE @courseQuizQuestionId INT;
    DECLARE @courseQuizId INT;
    DECLARE @courseId INT;
    DECLARE @symbol CHAR(1);
    DECLARE @answer NVARCHAR(256);

    DECLARE question_cursor CURSOR FOR
    SELECT id, courseQuizId, courseId
    FROM dbo.courseQuizQuestion;

    OPEN question_cursor;
    FETCH NEXT FROM question_cursor INTO @courseQuizQuestionId, @courseQuizId, @courseId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @symbol = 'A';
        WHILE @symbol <= 'D'
        BEGIN
            SET @answer = CASE @symbol
                              WHEN 'A' THEN 'Option A answer'
                              WHEN 'B' THEN 'Option B answer'
                              WHEN 'C' THEN 'Option C answer'
                              WHEN 'D' THEN 'Option D answer'
                          END;

            INSERT INTO dbo.courseQuizQuestionAnswer (courseQuizQuestionId, courseQuizId, courseId, symbol, answer)
            VALUES (@courseQuizQuestionId, @courseQuizId, @courseId, @symbol, @answer);

            SET @symbol = CHAR(ASCII(@symbol) + 1);
        END;

        FETCH NEXT FROM question_cursor INTO @courseQuizQuestionId, @courseQuizId, @courseId;
    END;

    CLOSE question_cursor;
    DEALLOCATE question_cursor;
END;
GO


IF OBJECT_ID('[dbo].[RandomizeFileData]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeFileData];
GO

CREATE PROCEDURE RandomizeFileData
AS
BEGIN
    DECLARE @id INT;
    DECLARE @path NVARCHAR(256);
    DECLARE @name NVARCHAR(128);
    DECLARE @counter INT = 1;

    WHILE @counter <= 100
    BEGIN
        SET @path = '/path/to/file' + CAST(@counter AS NVARCHAR(10)) + '.txt'; 
        SET @name = 'File ' + CAST(@counter AS NVARCHAR(10)); 

        INSERT INTO dbo.[file] (path, name)
        VALUES (@path, @name);

        SET @counter = @counter + 1;
    END;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseSectionFile]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseSectionFile];
GO

CREATE PROCEDURE RandomizeCourseSectionFile
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fileId INT;
    DECLARE @courseSectionId INT;
    DECLARE @courseId INT;

    DECLARE file_cursor CURSOR FOR
    SELECT id FROM dbo.[file];

    OPEN file_cursor;

    FETCH NEXT FROM file_cursor INTO @fileId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT TOP 1 @courseSectionId = id, @courseId = courseId
        FROM dbo.courseSection
        ORDER BY NEWID();

        BEGIN TRY
            INSERT INTO dbo.courseSectionFile (id, courseSectionId, courseId)
            VALUES (@fileId, @courseSectionId, @courseId);
        END TRY
        BEGIN CATCH
            PRINT 'Skipping duplicate file ID ' + CAST(@fileId AS NVARCHAR(10));
        END CATCH;

        FETCH NEXT FROM file_cursor INTO @fileId;
    END;

    CLOSE file_cursor;
    DEALLOCATE file_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseExerciseSolutionFile]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseExerciseSolutionFile];
GO

CREATE PROCEDURE RandomizeCourseExerciseSolutionFile
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fileId INT;
    DECLARE @courseExerciseId INT;
    DECLARE @courseId INT;

    DECLARE file_cursor CURSOR FOR
    SELECT id FROM dbo.[file];

    OPEN file_cursor;

    FETCH NEXT FROM file_cursor INTO @fileId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT TOP 1 @courseExerciseId = id, @courseId = courseId
        FROM dbo.courseExercise
        ORDER BY NEWID();

        BEGIN TRY
            INSERT INTO dbo.courseExerciseSolutionFile (id, courseExerciseId, courseId)
            VALUES (@fileId, @courseExerciseId, @courseId);
        END TRY
        BEGIN CATCH
            PRINT 'Skipping duplicate file ID ' + CAST(@fileId AS NVARCHAR(10));
        END CATCH;

        FETCH NEXT FROM file_cursor INTO @fileId;
    END;

    CLOSE file_cursor;
    DEALLOCATE file_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseSectionProgress]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseSectionProgress];
GO

CREATE PROCEDURE RandomizeCourseSectionProgress
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @learnerEmail VARCHAR(256);
    DECLARE @courseId INT;
    DECLARE @courseSectionId INT;
    DECLARE @completionPercentage FLOAT;

    DECLARE enrolled_cursor CURSOR FOR
    SELECT learnerEmail, courseId FROM dbo.enrolledCourse;

    OPEN enrolled_cursor;

    FETCH NEXT FROM enrolled_cursor INTO @learnerEmail, @courseId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE courseSection_cursor CURSOR FOR
        SELECT id FROM dbo.courseSection WHERE courseId = @courseId;

        OPEN courseSection_cursor;

        FETCH NEXT FROM courseSection_cursor INTO @courseSectionId;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @completionPercentage = CAST(RAND(CHECKSUM(NEWID())) AS FLOAT);

            BEGIN TRY
                INSERT INTO dbo.courseSectionProgress (learnerEmail, courseId, courseSectionId, completionPercentage)
                VALUES (@learnerEmail, @courseId, @courseSectionId, @completionPercentage);
            END TRY
            BEGIN CATCH
                PRINT 'Skipping duplicate entry for learnerEmail ' + @learnerEmail + ', courseId ' + CAST(@courseId AS NVARCHAR(10)) + ', courseSectionId ' + CAST(@courseSectionId AS NVARCHAR(10));
            END CATCH;

            FETCH NEXT FROM courseSection_cursor INTO @courseSectionId;
        END;

        CLOSE courseSection_cursor;
        DEALLOCATE courseSection_cursor;

        FETCH NEXT FROM enrolled_cursor INTO @learnerEmail, @courseId;
    END;

    CLOSE enrolled_cursor;
    DEALLOCATE enrolled_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseExerciseProgress]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseExerciseProgress];
GO

CREATE PROCEDURE RandomizeCourseExerciseProgress
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @learnerEmail VARCHAR(256);
    DECLARE @courseId INT;
    DECLARE @courseSectionId INT;
    DECLARE @savedTextSolution NVARCHAR(MAX);
    DECLARE @grade FLOAT;

    DECLARE progress_cursor CURSOR FOR
    SELECT learnerEmail, courseId, courseSectionId FROM dbo.courseSectionProgress;

    OPEN progress_cursor;

    FETCH NEXT FROM progress_cursor INTO @learnerEmail, @courseId, @courseSectionId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @savedTextSolution = 'Random solution text ' + CAST(NEWID() AS NVARCHAR(36));

        SET @grade = ROUND(RAND(CHECKSUM(NEWID())) * 10, 2);

        BEGIN TRY
            INSERT INTO dbo.courseExerciseProgress (learnerEmail, courseId, courseSectionId, savedTextSolution, grade)
            VALUES (@learnerEmail, @courseId, @courseSectionId, @savedTextSolution, @grade);
        END TRY
        BEGIN CATCH
            PRINT 'Skipping duplicate entry for learnerEmail ' + @learnerEmail + ', courseId ' + CAST(@courseId AS NVARCHAR(10)) + ', courseSectionId ' + CAST(@courseSectionId AS NVARCHAR(10));
        END CATCH;

        FETCH NEXT FROM progress_cursor INTO @learnerEmail, @courseId, @courseSectionId;
    END;

    CLOSE progress_cursor;
    DEALLOCATE progress_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseChat]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseChat];
GO

CREATE PROCEDURE RandomizeCourseChat
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @courseId INT;
    DECLARE @chatId INT;

    DECLARE course_cursor CURSOR FOR
    SELECT id FROM dbo.course;

    OPEN course_cursor;

    FETCH NEXT FROM course_cursor INTO @courseId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO dbo.chat DEFAULT VALUES;

        SET @chatId = SCOPE_IDENTITY();

        BEGIN TRY
            INSERT INTO dbo.courseChat (id, courseId)
            VALUES (@chatId, @courseId);
        END TRY
        BEGIN CATCH
            PRINT 'Skipping duplicate entry for courseId ' + CAST(@courseId AS NVARCHAR(10));
        END CATCH;

        FETCH NEXT FROM course_cursor INTO @courseId;
    END;

    CLOSE course_cursor;
    DEALLOCATE course_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeCourseChatMember]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeCourseChatMember];
GO

CREATE PROCEDURE RandomizeCourseChatMember
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @courseChatId INT;
    DECLARE @courseId INT;
    DECLARE @userEmail VARCHAR(256);

    DECLARE courseChat_cursor CURSOR FOR
    SELECT id, courseId FROM dbo.courseChat;

    OPEN courseChat_cursor;

    FETCH NEXT FROM courseChat_cursor INTO @courseChatId, @courseId;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO dbo.courseChatMember (userEmail, chatId)
        SELECT oc.ownerEmail, @courseChatId
        FROM dbo.ownedCourse oc
        WHERE oc.courseId = @courseId;

        INSERT INTO dbo.courseChatMember (userEmail, chatId)
        SELECT ec.learnerEmail, @courseChatId
        FROM dbo.enrolledCourse ec
        WHERE ec.courseId = @courseId;

        FETCH NEXT FROM courseChat_cursor INTO @courseChatId, @courseId;
    END;

    CLOSE courseChat_cursor;
    DEALLOCATE courseChat_cursor;
END;
GO

IF OBJECT_ID('[dbo].[RandomizePrivateChat]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizePrivateChat];
GO

CREATE PROCEDURE RandomizePrivateChat
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @counter INT = 0;
    DECLARE @max_records INT = 100000;
    DECLARE @chatId INT;

    DECLARE @email1 VARCHAR(256);
    DECLARE @email2 VARCHAR(256);

    CREATE TABLE #users (email VARCHAR(256));
    INSERT INTO #users (email)
    SELECT email FROM dbo.[user];

    DECLARE user_cursor CURSOR FOR
    SELECT email FROM #users;

    OPEN user_cursor;
    FETCH NEXT FROM user_cursor INTO @email1;

     WHILE @@FETCH_STATUS = 0 AND @counter < @max_records
    BEGIN
        SELECT TOP 1 @email2 = email
        FROM #users
        WHERE email <> @email1
        ORDER BY NEWID();

        IF @email1 > @email2
        BEGIN
            DECLARE @tempEmail VARCHAR(256);
            SET @tempEmail = @email1;
            SET @email1 = @email2;
            SET @email2 = @tempEmail;
        END

        BEGIN TRY
            INSERT INTO dbo.chat DEFAULT VALUES;
            SET @chatId = SCOPE_IDENTITY();

            INSERT INTO dbo.privateChat (id, email1, email2)
            VALUES ( @chatId, @email1, @email2);
            SET @counter = @counter + 1;
        END TRY
        BEGIN CATCH
            print('error')
        END CATCH

        FETCH NEXT FROM user_cursor INTO @email1;
    END;

    CLOSE user_cursor;
    DEALLOCATE user_cursor;

    DROP TABLE #users;
END;
GO

IF OBJECT_ID('[dbo].[RandomizeMessageAndNotification]', 'P') IS NOT NULL
    DROP PROCEDURE [dbo].[RandomizeMessageAndNotification];
GO

CREATE PROCEDURE RandomizeMessageAndNotification
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @counter INT = 0;
    DECLARE @max_records INT = 1000; 
    DECLARE @senderEmail VARCHAR(256);
    DECLARE @receiverEmail VARCHAR(256);
    DECLARE @chatId INT;
    DECLARE @content NVARCHAR(512);
    DECLARE @title NVARCHAR(64);
    DECLARE @messageContent NVARCHAR(512);
    DECLARE @notificationContent NVARCHAR(512);
    DECLARE @createdAt DATETIME = GETDATE();
    DECLARE @expiresAt DATE = DATEADD(DAY, 28, @createdAt);

    CREATE TABLE #RandomEmails (
        email VARCHAR(256) NOT NULL,
        CONSTRAINT PK_RandomEmails PRIMARY KEY (email)
    );

    INSERT INTO #RandomEmails (email)
    SELECT DISTINCT email FROM [dbo].[user] WHERE email IN (
        SELECT email FROM [dbo].[lecturer]
        UNION
        SELECT email FROM [dbo].[learner]
    );

    CREATE TABLE #ChatIDs (
        chatId INT NOT NULL,
        CONSTRAINT PK_ChatIDs PRIMARY KEY (chatId)
    );

    INSERT INTO #ChatIDs (chatId)
    SELECT DISTINCT id FROM [dbo].[chat];

    DECLARE email_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT email FROM #RandomEmails ORDER BY NEWID();

    OPEN email_cursor;

    FETCH NEXT FROM email_cursor INTO @senderEmail;

    WHILE @@FETCH_STATUS = 0 AND @counter < @max_records
    BEGIN
        FETCH NEXT FROM email_cursor INTO @receiverEmail;

        IF @senderEmail <> @receiverEmail
        BEGIN
            SELECT TOP 1 @chatId = chatId FROM #ChatIDs ORDER BY NEWID();

            SET @messageContent = @senderEmail + N' gửi tin nhắn';
            SET @notificationContent = N'Thông báo tin nhắn được gửi từ ' + @senderEmail;
            SET @title = N'Tin nhắn mới từ ' + @senderEmail;

            INSERT INTO dbo.message (senderEmail, chatId, content)
            VALUES (@senderEmail, @chatId, @messageContent);

            INSERT INTO dbo.notification (senderEmail, receiverEmail, title, content, expiresAt)
            VALUES (@senderEmail, @receiverEmail, @title, @notificationContent, @expiresAt);

            SET @counter = @counter + 1;
        END
    END;

    CLOSE email_cursor;
    DEALLOCATE email_cursor;

    DROP TABLE #RandomEmails;
    DROP TABLE #ChatIDs;
END;
GO






EXEC InsertCourseCategory;
EXEC RandomizeCourseDescriptionDetail;
EXEC RandomizeOwnedCourse;
EXEC RandomizeCourseAnnouncement;
EXEC RandomizeEnrolledCourse;
EXEC RandomizeCourseReview;
EXEC RandomizeCourseSection;
EXEC RandomizeCourseLesson;
EXEC RandomizeCourseExercise;
EXEC RandomizeCourseQuiz;
EXEC RandomizeCourseQuizQuestion;
EXEC RandomizeCourseQuizQuestionAnswer;
EXEC RandomizeFileData;
EXEC RandomizeCourseSectionFile;
EXEC RandomizeCourseExerciseSolutionFile;
EXEC RandomizeCourseSectionProgress;
EXEC RandomizeCourseExerciseProgress;
EXEC RandomizeCourseChat;
EXEC RandomizeCourseChatMember;
EXEC RandomizePrivateChat;
EXEC RandomizeMessageAndNotification;