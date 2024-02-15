import ballerina/graphql;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string host = ?;
configurable string username = ?;
configurable string password = ?;
configurable string databaseName = ?;
configurable int port = ?;

final mysql:Client db = check new (host, username, password, databaseName, port);

@graphql:ServiceConfig {
    graphiql: {
        enabled: true
    }
}
service /bank on new graphql:Listener(9094) {
    resource function get accounts() returns Account[]|error {
        return queryAccountData();
    }
}

type BankEmployee record {
    int id;
    string name;
    string position;
};

type Account record {
    int number;
    string accType;
    string holder;
    string address;
    string openedDate;
    BankEmployee bankEmployee;
};

type DBAccount record {|
    int acc_number;
    string account_type;
    string account_holder;
    string address;
    string opened_date;
    int employee_id;
    string position;
    string name;
|};

function queryAccountData() returns Account[]|error {
    stream<DBAccount, sql:Error?> accountStream = db->query(`SELECT a.acc_number, a.account_type, a.account_holder, a.address, 
    a.opened_date, e.employee_id, e.position, e.name from Accounts a LEFT JOIN Employees e on a.employee_id  = e.employee_id; `);

    DBAccount[] dbAccounts = check from DBAccount dbAccount in accountStream
        select dbAccount;
    return transform(dbAccounts);
}

function transform(DBAccount[] dbAccount) returns Account[] => from var dbAccountItem in dbAccount
    select {
        number: dbAccountItem.acc_number,
        accType: dbAccountItem.account_type,
        holder: dbAccountItem.account_holder,
        address: dbAccountItem.address,
        openedDate: dbAccountItem.opened_date,
        bankEmployee: {
            id: dbAccountItem.employee_id,
            name: dbAccountItem.name,
            position: dbAccountItem.position
        }
    };
