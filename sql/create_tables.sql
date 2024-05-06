START TRANSACTION;

-- Add table transactions
CREATE TABLE IF NOT EXISTS transactions (
	time TIMESTAMP,
	hour_of_day INT,
	sending_address VARCHAR(50),
	receiving_address VARCHAR(50),
	amount FLOAT NOT NULL,
	transaction_type VARCHAR(10),
	location_region VARCHAR(15),
	ip_prefix VARCHAR(7),
	login_frequency INT,
	session_duration INT,
	purchase_pattern VARCHAR(10),
	age_group VARCHAR(15),
	risk_score FLOAT NOT NULL,
	anomaly VARCHAR(15)
);

COMMIT;
