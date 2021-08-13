var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var logger = require('morgan');
var session = require('express-session');
var passport = require('passport');
var bodyParser = require('body-parser');
const crypto = require('crypto');
const expressLayouts = require('express-ejs-layouts');
var app = express();
var config  = require('./config');



const PAYPAY = require('@paypayopa/paypayopa-sdk-node');
PAYPAY.Configure({
    clientId: config.clientId,
    clientSecret: config.clientSecret,
    merchantId: config.merchantId,
    productionMode: false,
});

// MySQL
const mysql = require('mysql2');
const { SSL_OP_SSLEAY_080_CLIENT_DH_BUG } = require('constants');
const { token } = require('morgan');
const { traceDeprecation } = require('process');

var pool = mysql.createPool({
    connectionLimit: 10,
    host: 'localhost',
    user: 'root',
    password: config.dbPass,
    database: 'test1'
});

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');
app.use(expressLayouts);

// express
app.use(logger('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));

// cookie
app.use(cookieParser());

// passport
app.use(passport.initialize());
app.use(session({
    secret: config.cookie,
}));
app.use(passport.session());

// body parser
app.use(bodyParser.urlencoded({ extended: true }));

// error handler
app.use(function (err, req, res, next) {
    // set locals, only providing error in development
    res.locals.message = err.message;
    res.locals.error = req.app.get('env') === 'development' ? err : {};

    // render the error page
    res.status(err.status || 500);
    res.render('error');
});

//authenticated checker
function isAuthenticated(req, res, next) {
    if (req.cookies['login_flag'] == 'true') {
        return next();
    }
    else {
        res.redirect('/adminlogin');
    }
}

//token-checker
function isTrueToken(req, res, next) {
    var sql = "SELECT Token, Token_limit FROM Patient WHERE Patient_id='" + req.query['Patient_id'] + "';";
    pool.query(sql, (error, token) => {
        var current_time = Date.now();
        if (req.query['token'] == token[0].Token && current_time < token[0].Token_limit) {
            next();
        } else {
            res.send({ failure: "true" });
        }
    });
}

function isTrueTokenForPost(req, res, next) {
    var sql = "SELECT Token, Token_limit FROM Patient WHERE Patient_id='" + req.body['Patient_id'] + "';";
    pool.query(sql, (error, token) => {
        var current_time = Date.now();
        if (req.body['token'] == token[0].Token && current_time < token[0].Token_limit) {
            next();
        } else {
            res.send({ failure: "true" });
        }
    });
}

//userloginauth
function userAuth(req, res, next) {
    sql = "SELECT Password FROM Patient where User_name='" + req.body['username'] + "';";
    pool.query(sql, (error, db_pass) => {
        const hashed_password = crypto.createHash('sha256').update(req.body['password']).digest('hex');
        if (db_pass[0].Password == hashed_password) {
            next();
        } else {
            res.send({ failure: "true" });
        }
    });
}

/******************** User *********************/
// There are APIs

/******** User Registration ********/
app.post('/register', function (req, res) {
    var username = req.body['username'];
    var password = req.body['password'];
    const hashed_password = crypto.createHash('sha256').update(password).digest('hex');
    const N = 10;
    var Patient_id = crypto.randomInt(100000000);
    const sql = "INSERT INTO Patient(Patient_id, User_Name, Password) VALUES('" + Patient_id + "','" + username + "','" + hashed_password + "');";
    pool.query(sql, (error, results) => {
        if (error) throw error;
    });
    res.json({ text: 'Registration success.' });
})

/******** User Login ********/
app.post('/login', userAuth,
    function (req, res) {
        //new token
        var token = crypto.randomBytes(20).toString('hex');
        var limit = Date.now() + 1000 * 3600 * 72;
        //update
        var sql = "UPDATE Patient SET Token='" + token + "', Token_limit='" + limit + "' WHERE User_name='" + req.body['username'] + "';";
        pool.query(sql, (error, result) => {
            console.log(result);
        });

        //send user_id
        sql = "SELECT Patient_id FROM Patient where User_name='" + req.body['username'] + "';";
        pool.query(sql, (error, user_id) => {
            res.send({ token: token, Patient_id: user_id[0].Patient_id });
        });
    }
);

app.get('/prescription/:prescription_id', isTrueToken, (req, res) => {
    let merchantPaymentId = req.query['Merchant_payment_id'];
    PAYPAY.GetCodePaymentDetails(Array(merchantPaymentId), (response) => {
        var body = JSON.parse(response.BODY);
        var sql = "SELECT * FROM Payment_Info WHERE Patient_id='" + req.query['Patient_id'] + "';";
        pool.query(sql, (error, payment) => {
            sql = "SELECT * FROM Prescription WHERE Prescription_id='" + req.params.prescription_id + "';";
            pool.query(sql, (error, results) => {
                sql = "SELECT * FROM Phrmacy WHERE Pharmacy_id=" + results[0].Pharmacy_id + ";"
                pool.query(sql, (error, pharmacy) => {
                    sql = "SELECT * FROM Pharmacy_has_Station WHERE Pharmacy_id=" + results[0].Pharmacy_id + ";";
                    pool.query(sql, (error, has_station) => {
                        sql = "SELECT * FROM Station WHERE Station_id=" + has_station[0].Station_id + ";";
                        pool.query(sql, (error, station) => {
                            sql = "SELECT * FROM Medicine WHERE Medicine_id='" + results[0].Medicine_id + "';";
                            pool.query(sql, (error, medicine) => {
                                sql = "SELECT * FROM Ingredients WHERE Typical_Ingredients_ID='" + medicine[0].Typical_Ingredients_ID + "';";
                                pool.query(sql, (error, ingredients) => {
                                    if (body.resultInfo.code == "SUCCESS" && body.data.status == "COMPLETED") {
                                        //generate QR CODE And send that data.
                                        var qr_data = { Medicine_Name: medicine[0].Medicine_Name, Medicine_Shape: medicine[0].Medicine_Shape, }
                                        const iv = crypto.randomBytes(16);
                                        const cipher = crypto.createCipheriv('aes-256-cbc', 'test', iv);
                                        const encData = cipher.update(Buffer.from(qr_data));
                                        QR = Buffer.concat([iv, encData, cipher.final()]).toString('base64');
                                    } else {
                                        QR = "";
                                    }
                                    res.send({ QR: QR, Merchant_payment_id: payment[0].Merchant_payment_id, Prescription_id: results[0].Prescription_id, Medicine_Name: medicine[0].Medicine_Name, Medicine_Shape: medicine[0].Medicine_Shape, Ingredients: ingredients[0].Typical_Ingredients, Station: station[0].Name });
                                });
                            });
                        });
                    });
                });
            });
        });
    });
});

/******** Data for user ********/
app.get('/prescription', isTrueToken, (req, res) => {
    items = [];
    var sql = "SELECT * FROM Prescription WHERE Patient_id='" + req.query['Patient_id'] + "';";
    pool.query(sql, (error, results) => {
        results.forEach(function (item, index) {
            sql = "SELECT Medicine_Name FROM Medicine WHERE Medicine_id=" + item.Medicine_id + ";";
            pool.query(sql, (error, Medicine_Name) => {
                sql = "SELECT Station_id FROM Pharmacy_has_Station WHERE Pharmacy_id=" + item.Pharmacy_id + ";";
                pool.query(sql, (error, Station_id) => {
                    sql = "SELECT Name FROM Station WHERE Station_id=" + Station_id[0].Station_id + ";";
                    pool.query(sql, (error, Station_Name) => {
                        items.push({ prescription_id: item.Prescription_id, Date: item.Date, Medicine_Name: Medicine_Name[0].Medicine_Name, Amount: item.Total_Frequency, station: Station_Name[0].Name });
                        if (items.length == results.length) {
                            res.send(items);
                            return;
                        }
                    });
                });
            });
        });
    });
});

app.post('/prescription', isTrueTokenForPost, (req, res) => {
    const N = 10;
    var Prescription_id = crypto.randomInt(10000000);
    var sql = "INSERT INTO Prescription(Prescription_id, Date, Total_Frequency, Patient_id, Medicine_id, Pharmacy_id) VALUES(" + Prescription_id + ", " + Date.now() + ", " + req.body['Frequency'] + ", " + req.body['Patient_id'] + ", " + req.body['Medicine_id'] + ", " + req.body['Pharmacy_id'] + ");";
    pool.query(sql, (error, results) => {
        if (error) throw error;

        var prescription_id = Prescription_id;
        sql = "SELECT Total_Frequency,Medicine_id FROM Prescription WHERE Prescription_id=" + prescription_id + ";";
        pool.query(sql, (error, Medicine_id) => {
            sql = "SELECT Actual_Cost FROM Medicine WHERE Medicine_id=" + Medicine_id[0].Medicine_id + ";";
            pool.query(sql, (error, Actual_Cost) => {
                amount = Math.round(Actual_Cost[0].Actual_Cost * Medicine_id[0].Total_Frequency);
                let payload = {
                    merchantPaymentId: crypto.randomBytes(12).reduce((p, i) => p + (i % 36).toString(36), ''),
                    amount: {
                        amount: amount,
                        currency: "JPY"
                    },
                    codeType: "ORDER_QR",
                    orderDescription: "Prescription",
                    isAuthorization: false,
                    redirectUrl: "/",
                    redirectType: "APP_DEEP_LINK",
                    userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 10_3 like Mac OS X) AppleWebKit/602.1.50 (KHTML, like Gecko) CriOS/56.0.2924.75 Mobile/14E5239e Safari/602.1"
                };
                // Calling the method to create a qr code
                PAYPAY.QRCodeCreate(payload, (response) => {
                    // Printing if the method call was SUCCESS
                    var body = JSON.parse(response.BODY);
                    if (response.STATUS == 201) {
                        sql = "INSERT INTO Payment_Info(Payment_id,Cost,Patient_id, Merchant_payment_id) VALUES(" + crypto.randomInt(10000) + "," + amount + ",'" + req.body.Patient_id + "','" + body.data.merchantPaymentId + "');";
                        pool.query(sql, (error, results) => {
                            if (error) throw error;
                            res.send({ Merchant_payment_id: body.data.merchantPaymentId, url: body.data.url });
                        });
                    }
                });
            });
        });
    });
});


/******************** Admin *********************/
//There are Web Pages

/******** Admin Login ********/

app.get('/adminlogin', (req, res) => {
    res.render(__dirname + "/views/adminlogin.ejs");
});

app.post('/adminlogin', (req, res) => {
    username = req.body['username'];
    const sql = "SELECT password FROM Admin WHERE username = '" + username + "';";
    pool.query(sql, (error, server_password) => {
        if (error) console.log(error);
        const hashed_password = crypto.createHash('sha256').update(req.body['password']).digest('hex');
        if (server_password[0].password == hashed_password) {
            res.cookie('login_flag', 'true', {
                maxAge: 120000,
                httpOnly: false
            });
            res.redirect('/prescription-list');
        } else {
            res.redirect('/failure');
        }
    });
});

/******** Admin Logout ********/
app.get('/adminlogout', (req, res) => {
    res.clearCookie('login_flag');
    res.redirect('/adminlogin');
});

app.get('/failure', (req, res) => {
    res.render(__dirname + "/views/failure.ejs",);
})

/******** Prescription List ********/
app.get('/prescription-list', isAuthenticated, (req, res) => {
    const sql = "SELECT * FROM Prescription;";
    pool.query(sql, (error, Prescription) => {
        if (error) throw error;
        res.render(__dirname + "/views/prescription-list.ejs", { Prescription: Prescription });
    });
});

/******** User List ********/
app.get('/patient-list', isAuthenticated, (req, res) => {
    const sql = "SELECT * FROM Patient;";
    pool.query(sql, (error, Patient) => {
        if (error) throw error;
        res.render(__dirname + "/views/patient-list.ejs", { Patient: Patient });
    });
});

/******** Medicine List ********/
app.get('/medicine-list', isAuthenticated, (req, res) => {
    const sql = "SELECT * FROM Medicine;";
    pool.query(sql, (error, Medicine) => {
        if (error) throw error;
        res.render(__dirname + "/views/medicine-list.ejs", { Medicine: Medicine });
    });
});

/******** Medicine List ********/
app.get('/payment-list', isAuthenticated, (req, res) => {
    const sql = "SELECT * FROM Payment_Info;";
    pool.query(sql, (error, Payment) => {
        if (error) throw error;
        res.render(__dirname + "/views/payment-list.ejs", { Payment: Payment });
    });
});


// server listener
var server = app.listen(config.port, function () {
    var host = server.address().address;
    var port = server.address().port;
});
