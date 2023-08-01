-- Create Database
DROP DATABASE IF EXISTS `homework_db`;
CREATE DATABASE IF NOT EXISTS `homework_db`;
USE homework_db;

-- Table food_type
DROP TABLE IF EXISTS `food_type`;
CREATE TABLE `food_type` (
	`type_id` int NOT NULL AUTO_INCREMENT,
	`type_name` varchar(100) NOT NULL UNIQUE,
	PRIMARY KEY (`type_id`)
);

-- Table food
DROP TABLE IF EXISTS `food`;
CREATE TABLE `food` (
    `food_id` INT NOT NULL AUTO_INCREMENT,
    `food_name` VARCHAR(100) NOT NULL,
    `image` VARCHAR(255) NOT NULL,
    `price` FLOAT NOT NULL CHECK (price >= 0.0),
    `desc` VARCHAR(255) DEFAULT "No Description",
    PRIMARY KEY (`food_id`)
);

-- Table sub_food
DROP TABLE IF EXISTS `sub_food`;
CREATE TABLE `sub_food` (
	`sub_id` int NOT NULL AUTO_INCREMENT,
	`sub_name` varchar(100) NOT NULL,
    `sub_price` float NOT NULL CHECK (sub_price >= 0.0),
	PRIMARY KEY (`sub_id`)
);

-- Table user
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
	`user_id` int NOT NULL AUTO_INCREMENT,
	`full_name` varchar(100) NOT NULL,
    `email` varchar(255) NOT NULL UNIQUE,
    CHECK (email REGEXP '^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$'),
    `password` varchar(255) NOT NULL,
	PRIMARY KEY (`user_id`)
);

-- Table order
DROP TABLE IF EXISTS `order`;
CREATE TABLE `order` (
	`amount` int NOT NULL CHECK (amount >= 1),
    `code` varchar(255) NOT NULL UNIQUE,
    `arr_sub_id` varchar(255) DEFAULT "[]"
);

-- Table restaurant
DROP TABLE IF EXISTS `restaurant`;
CREATE TABLE `restaurant` (
    `res_id` INT NOT NULL AUTO_INCREMENT,
    `res_name` VARCHAR(100) NOT NULL,
    `image` VARCHAR(255) NOT NULL,
    `desc` VARCHAR(255) DEFAULT "No Description",
    PRIMARY KEY (`res_id`)
);

-- Table rate_res
DROP TABLE IF EXISTS `rate_res`;
CREATE TABLE `rate_res` (
	`amount` int NOT NULL CHECK (amount >= 0),
    `date_rate` datetime default NOW()
);

-- Table like_res
DROP TABLE IF EXISTS `like_res`;
CREATE TABLE `like_res` (
    `date_like` datetime default NOW()
);

-- Relationship 1 - n (food_type - food)
ALTER TABLE `food`
ADD COLUMN `type_id` INT NOT NULL,
ADD CONSTRAINT `fk_food_type` FOREIGN KEY (`type_id`) REFERENCES `food_type` (`type_id`);

-- Relationship 1 - n (food - sub_food)
ALTER TABLE `sub_food`
ADD COLUMN `food_id` INT NOT NULL,
ADD CONSTRAINT `fk_food` FOREIGN KEY (`food_id`) REFERENCES `food` (`food_id`);

-- Relationship n - n (food - user)
ALTER TABLE `order`
ADD COLUMN `food_id` INT NOT NULL,
ADD COLUMN `user_id` INT NOT NULL,
ADD CONSTRAINT `fk_order_food` FOREIGN KEY (`food_id`) REFERENCES `food` (`food_id`),
ADD CONSTRAINT `fk_order_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

-- Relationship n - n (restaurant - user)
ALTER TABLE `rate_res`
ADD COLUMN `res_id` INT NOT NULL,
ADD COLUMN `user_id` INT NOT NULL,
ADD CONSTRAINT `fk_rate_res` FOREIGN KEY (`res_id`) REFERENCES `restaurant` (`res_id`),
ADD CONSTRAINT `fk_rate_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

-- Relationship n - n (restaurant - user)
ALTER TABLE `like_res`
ADD COLUMN `res_id` INT NOT NULL,
ADD COLUMN `user_id` INT NOT NULL,
ADD CONSTRAINT `fk_like_res` FOREIGN KEY (`res_id`) REFERENCES `restaurant` (`res_id`),
ADD CONSTRAINT `fk_like_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`);

-- Create Trigger For Check Valid Email
DELIMITER //
CREATE TRIGGER check_email_valid
BEFORE INSERT ON `user`
FOR EACH ROW
BEGIN
    DECLARE email_valid BOOLEAN;
    SET email_valid = NEW.email REGEXP '^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}$';
    IF NOT email_valid THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid email format';
    END IF;
END //
DELIMITER ;

-- Create Function For Take Json Object From arr_sub_id
DELIMITER //
CREATE FUNCTION getDetailArr_sub_id(order_code VARCHAR(255))
RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE order_id VARCHAR(255);
    DECLARE sub_foods JSON;
    DECLARE term_food JSON;
    DECLARE sub_id_str VARCHAR(255);
    DECLARE get_sub_id INT;
    SET order_id = (SELECT code FROM `order` WHERE code = order_code);

    IF order_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    END IF;

    SET sub_foods = JSON_ARRAY();
    SET sub_id_str = (SELECT arr_sub_id FROM `order` WHERE code = order_code);
    SET sub_id_str = SUBSTRING_INDEX(SUBSTRING_INDEX(sub_id_str, '[', -1), ']', 1);

	IF CHAR_LENGTH(sub_id_str) > 0 THEN
		WHILE CHAR_LENGTH(sub_id_str) > 0 DO
			SET get_sub_id = cast(SUBSTRING_INDEX(sub_id_str, ',', 1) as SIGNED);
			SET sub_id_str = TRIM(BOTH ',' FROM SUBSTRING(sub_id_str, CHAR_LENGTH(get_sub_id) + 2));
            
			SELECT JSON_OBJECT('sub_id', sub_id, 'sub_name', sub_name)
			INTO term_food
			FROM sub_food
			WHERE sub_id = get_sub_id;
            
            SET sub_foods = JSON_ARRAY_APPEND(sub_foods, '$', JSON_EXTRACT(term_food, '$'));
		END WHILE;
	END IF;

    RETURN sub_foods;
END //
DELIMITER ;

INSERT INTO `food_type` (`type_name`) VALUES
    ('Italian'),
    ('American'),
    ('Japanese'),
    ('Chinese'),
    ('Indian'),
    ('Mexican'),
    ('Thai'),
    ('Korean'),
    ('Greek'),
    ('French');

INSERT INTO `food` (`food_name`, `image`, `price`, `desc`, `type_id`) VALUES
    ('Pizza Margherita', 'pizza_margherita.jpg', 10.99, 'Classic Italian pizza with tomatoes, mozzarella, and basil.', 1),
    ('Hamburger', 'hamburger.jpg', 8.99, 'Juicy beef patty with cheese, lettuce, and tomato.', 2),
    ('Sushi Roll', 'sushi_roll.jpg', 12.99, 'Fresh sushi roll with tuna, avocado, and cucumber.', 3),
    ('Kung Pao Chicken', 'kung_pao_chicken.jpg', 9.99, 'Spicy Chinese stir-fry with chicken, peanuts, and vegetables.', 4),
    ('Butter Chicken', 'butter_chicken.jpg', 11.99, 'Creamy Indian curry with chicken and tomato sauce.', 5),
    ('Tacos', 'tacos.jpg', 7.99, 'Authentic Mexican street tacos with grilled meat and toppings.', 6),
    ('Pad Thai', 'pad_thai.jpg', 10.99, 'Popular Thai noodle dish with shrimp, tofu, and peanuts.', 7),
    ('Bibimbap', 'bibimbap.jpg', 11.99, 'Korean rice bowl with mixed vegetables and meat.', 8),
    ('Greek Salad', 'greek_salad.jpg', 8.99, 'Healthy Greek salad with feta cheese, olives, and fresh vegetables.', 9),
    ('Croissant', 'croissant.jpg', 3.99, 'Flaky French pastry perfect for breakfast or snack.', 10);

INSERT INTO `sub_food` (`sub_name`, `sub_price`, `food_id`) VALUES
    ('Coca-Cola', 1.99, 1),
    ('French Fries', 2.49, 2),
    ('Salmon Nigiri', 3.99, 3),
    ('Spring Rolls', 2.99, 3),
    ('Naan Bread', 1.49, 4),
    ('Guacamole', 2.99, 5),
    ('Tom Yum Soup', 3.49, 6),
    ('Pepsi', 3.79, 2),
    ('Fanta', 1.49, 2),
    ('Kimchi', 1.99, 7),
    ('Olives', 1.49, 8),
    ('Pain au Chocolat', 2.99, 10);

INSERT INTO `user` (`full_name`, `email`, `password`) VALUES
    ('John Doe', 'john.doe@example.com', '12345'),
    ('Jane Smith', 'jane.smith@example.com', '54311rr'),
    ('Michael Johnson', 'michael.johnson@example.com', 'hello'),
    ('Emily Wang', 'emily.wang@example.com', 'hellokitty'),
    ('David Kim', 'david.kim@example.com', 'lovecat'),
    ('Sophia Lee', 'sophia.lee@example.com', '09090909'),
    ('James Brown', 'james.brown@example.com', '56ttt55'),
    ('Olivia Wilson', 'olivia.wilson@example.com', 'nodejs'),
    ('Daniel Martinez', 'daniel.martinez@example.com', 'thanks'),
    ('Jimmy Robert', 'jimmy.robert@example.com', 'mysql3306'),
    ('Isabella Taylor', 'isabella.taylor@example.com', 'this_is_password');

INSERT INTO `order` (`user_id`, `food_id`, `amount`, `code`, `arr_sub_id`) VALUES
    (2, 1, 2, 'ORDER001', '[1,2]'),
    (1, 2, 1, 'ORDER002', '[4,6]'),
    (3, 3, 3, 'ORDER003', '[3,5,7]'),
    (2, 4, 2, 'ORDER004', '[8,9]'),
    (1, 5, 1, 'ORDER005', '[10]'),
    (4, 6, 4, 'ORDER006', '[1,3,5,7]'),
    (3, 7, 1, 'ORDER007', '[2,4,6]'),
    (2, 8, 2, 'ORDER008', '[8,10]'),
    (1, 9, 3, 'ORDER009', '[9]'),
    (2, 10, 2, 'ORDER010', '[1,3]');

INSERT INTO `restaurant` (`res_name`, `image`, `desc`) VALUES
    ('Pasta Paradise', 'pasta_paradise.jpg', 'Cozy Italian restaurant serving delicious pasta dishes.'),
    ('Burger Heaven', 'burger_heaven.jpg', 'Classic American diner with the best burgers in town.'),
    ('Sushi Master', 'sushi_master.jpg', 'Top-notch Japanese sushi restaurant with skilled chefs.'),
    ('Spicy Wok', 'spicy_wok.jpg', 'Authentic Chinese restaurant offering spicy dishes.'),
    ('Curry House', 'curry_house.jpg', 'Popular Indian restaurant specializing in curry.'),
    ('Taco Fiesta', 'taco_fiesta.jpg', 'Lively Mexican eatery serving mouthwatering tacos.'),
    ('Thai Delight', 'thai_delight.jpg', 'Charming Thai restaurant with a variety of tasty dishes.'),
    ('K-Town Grill', 'k_town_grill.jpg', 'Korean BBQ restaurant with an extensive grill menu.'),
    ('Greek Oasis', 'greek_oasis.jpg', 'Relaxing Greek restaurant featuring healthy Mediterranean cuisine.'),
    ('Le Petit Croissant', 'le_petit_croissant.jpg', 'Quaint French bakery with delectable pastries.');

INSERT INTO `rate_res` (`amount`, `date_rate`, `res_id`, `user_id`) VALUES
    (5, '2023-07-20 12:30:45', 1, 3),
    (4, '2023-07-21 15:10:22', 2, 5),
    (3, '2023-07-22 18:45:11', 3, 2),
    (5, '2023-07-23 09:20:33', 4, 8),
    (4, '2023-07-24 14:55:57', 5, 1),
    (4, '2023-07-25 19:25:40', 6, 9),
    (5, '2023-07-26 10:15:18', 7, 4),
    (3, '2023-07-27 16:40:29', 8, 6),
    (4, '2023-07-28 20:05:37', 9, 7),
    (5, '2023-07-29 11:55:09', 10, 10);

INSERT INTO `like_res` (`date_like`, `res_id`, `user_id`) VALUES
    ('2023-07-20 13:45:22', 1, 1),
    ('2023-07-22 16:30:58', 2, 2),
    ('2023-07-24 19:20:11', 5, 2),
    ('2023-07-26 10:50:04', 2, 4),
    ('2023-07-28 14:15:39', 9, 1),
    ('2023-07-21 12:25:36', 2, 8),
    ('2023-07-23 15:55:42', 4, 1),
    ('2023-07-25 18:35:09', 8, 8),
    ('2023-07-27 11:10:57', 8, 2),
    ('2023-07-29 13:30:24', 8, 1);

-- Show detail of arr_sub_id
SELECT getDetailArr_sub_id("ORDER004");
SELECT getDetailArr_sub_id("ORDER005");
SELECT getDetailArr_sub_id("ORDER006");
SELECT getDetailArr_sub_id("ORDER007");

-- Tìm 5 người đã like nhà hàng nhiều nhất
SELECT 
    user.user_id,
    full_name,
    email,
    password,
    COUNT(like_res.user_id) AS like_count
FROM
    `user`
        INNER JOIN
    `like_res` ON user.user_id = like_res.user_id
GROUP BY user.user_id , full_name , email , password
ORDER BY like_count DESC
LIMIT 5;

-- Tìm 2 nhà hàng có lượt like nhiều nhất
SELECT 
    res.res_id,
    res_name,
    image,
    `desc`,
    COUNT(lr.res_id) AS like_count
FROM
    `restaurant` res
        INNER JOIN
    `like_res` lr ON res.res_id = lr.res_id
GROUP BY res.res_id , res_name , image , `desc`
ORDER BY like_count DESC
LIMIT 2;

-- Tìm người đã đặt hàng nhiều nhất
SELECT 
    user.user_id,
    full_name,
    email,
    password,
    COUNT(`order`.user_id) AS order_count
FROM
    `user`
        INNER JOIN
    `order` ON user.user_id = `order`.user_id
GROUP BY user.user_id , full_name , email , password
ORDER BY order_count DESC
LIMIT 1;

-- Tìm người dùng không hoạt động trong hệ thống (không đặt hàng, không like, không đánh giá nhà hàng)
SELECT user.user_id, user.full_name, user.email, user.password
FROM `user`
LEFT JOIN `order` ON user.user_id = `order`.user_id
LEFT JOIN `like_res` ON user.user_id = `like_res`.user_id
LEFT JOIN `rate_res` ON user.user_id = `rate_res`.user_id
WHERE `order`.user_id IS NULL AND `like_res`.user_id IS NULL AND `rate_res`.user_id IS NULL;

-- Tính trung bình sub_food của một food
SELECT 
    food.food_id,
    food.food_name,
    1.0 / COUNT(sub_food.sub_id) AS average_sub_food
FROM
    `food`
        LEFT JOIN
    `sub_food` ON food.food_id = sub_food.food_id
GROUP BY food.food_id , food.food_name;
