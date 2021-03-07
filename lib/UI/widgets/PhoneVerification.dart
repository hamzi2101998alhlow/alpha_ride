
import 'dart:convert';
import 'package:alpha_ride/Enum/StateAccount.dart';
import 'package:alpha_ride/Enum/TypeAccount.dart';
import 'package:alpha_ride/Helper/AppLocalizations.dart';
import 'package:alpha_ride/Helper/DataProvider.dart';
import 'package:alpha_ride/Helper/FirebaseHelper.dart';
import 'package:alpha_ride/Helper/SharedPreferencesHelper.dart';
import 'package:alpha_ride/Login.dart';
import 'package:alpha_ride/UI/Customers/CompleteCreateAccount.dart';
import 'package:alpha_ride/UI/Customers/Home.dart';
import 'package:alpha_ride/UI/Driver/homeDriver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:alpha_ride/Models/User.dart' as model;

import 'Timer.dart';
import 'autoFill_sms.dart';


class PhoneVerification extends StatefulWidget {

  String phoneNumber  ;

  TypeAccount typeAccount ;

  AuthCredential credential;

  String fullName , email  , imageProfile ;

  int flag ;

  PhoneVerification(this.phoneNumber , { this.imageProfile,this.email,this.typeAccount = TypeAccount.customer ,  this.credential , this.fullName , this.flag });

  @override
  _PhoneVerificationState createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification> {

  String actualCode ="" , smsCode ="" ;

  String appSignature;
  String otpCode;


 void  listenForCode() async{

   await SmsAutoFill().listenForCode;
  }

  @override
  void initState()  {
    super.initState();

    listenForCode();
     sendCode();

    SmsAutoFill().getAppSignature.then((signature) {
      setState(() {
        appSignature = signature;
      });
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(



      body: SafeArea(


        child:Stack(

          children: [

            Padding(
              padding: EdgeInsets.only(left: 25 ,  top: 25),
              child: InkWell(

                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios_rounded , color: DataProvider().baseColor,),
              ),
            ),


            Padding(
              padding: EdgeInsets.all(40.0),


              child: Column(


                children: [

                  if(inProgress)
                  SizedBox(
                    height: 35.0,
                  ),

                  if(inProgress)
                    LinearProgressIndicator(
                    backgroundColor: DataProvider().baseColor,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber,),
                  ),


                  SizedBox(
                    height: 35.0,
                  ),


                  Text("${AppLocalizations.of(context).translate('enterCodeVerification')}" ,
                    style: TextStyle(

                        fontWeight: FontWeight.bold ,
                        fontSize: 20.0
                    ),),

                  SizedBox(
                    height: 20.0,
                  ),


                  Padding(padding: EdgeInsets.only(left: 40.0 ,right: 40.0) ,
                    child:  buildPinFieldAutoFill(),
                  ) ,

                  SizedBox(
                    height: 20.0,
                  ),

                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: MaterialButton(

                      onPressed:  () {

                        verification();
                      },//since this is only a UI app
                      child: Text('${AppLocalizations.of(context).translate('verification')}',
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'SFUIDisplay',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      color: DataProvider().baseColor,
                      elevation: 0,
                      minWidth: 400,
                      height: 50,
                      textColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                      ),
                    ),
                  ),

                  SizedBox(
                    height: 15.0,
                  ),


                  Timer(),

                  SizedBox(height: 20.0,) ,



                ],

              ),

            )
          ],
        ),

      ),

    );
  }

  PinFieldAutoFill buildPinFieldAutoFill() {
    return  PinFieldAutoFill(

                autofocus: true,
                onCodeChanged: (txt)  {

                  print(txt);
                },
                codeLength:  6 , //code length, default 6
              );
  }


  var firebaseAuth =  FirebaseAuth.instance;


 bool inProgress = false ;
  void verification (){

    this.setState(() {
      inProgress = true ;
    });

    AuthCredential phoneAuthCredential =
        PhoneAuthProvider.credential(verificationId: actualCode , smsCode: "123456");


    if(phoneAuthCredential == null)
      return;


    firebaseAuth.signInWithCredential(phoneAuthCredential).then((c) => {


      if( widget.credential == null)
      FirebaseHelper().infoUserExit(c.user.uid).then((value) => {

        if(value){

          FirebaseHelper().loadUserInfo(c.user.uid).then((user) => {

            SharedPreferencesHelper().setFullName(user.fullName),
            SharedPreferencesHelper().setEmail(user.email),
            SharedPreferencesHelper().setSetTypeAccount(user.typeAccount),

            Navigator.push(context, MaterialPageRoute
              (builder: (context) => user.typeAccount == TypeAccount.customer ? Home()  : HomeDriver() ,)),
          })

        }
        else
       {

         if(widget.typeAccount == TypeAccount.customer)
           Navigator.push(context, MaterialPageRoute(builder: (context) => CompleteCreateAccount(c)))
         else
           requestNewAccountDriver(c.user.uid)


       },


      })
      else{

        c.user.linkWithCredential(widget.credential).then((value) {

          auth.currentUser.updateProfile(displayName: "${widget.fullName}" , photoURL: widget.imageProfile);

          FirebaseHelper().insertInformationUser(model.User(
              fullName: widget.fullName ,
              email:  widget.flag == 0 ?  widget.email : null,
              idUser: c.user.uid,
              stateAccount: StateAccount.active ,
              phoneNumber: widget.phoneNumber,
              imageProfile: widget.imageProfile,
              typeAccount: TypeAccount.customer,
              emailVerified: true ,
              emailFacebook: widget.flag == 1 ? widget.email : null
          )).then((value) {

            Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => Home(),), (route) => false);

          });


        }),


        },

      this.setState(() {
        inProgress = false ;
      }),


    }).catchError((err){

      this.setState(() {
        inProgress = false ;
      });

    });


  }


  void onSmsReceived(String message) {

    print(message);
  }

  void sendCode() async {

    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: '${widget.phoneNumber}',
      verificationCompleted: (credential) async {
        // ANDROID ONLY!

        //verification();

        String t = credential.toString().replaceAll("jsonObject", '"jsonObject"');

        var dt =   json.decode(t);

        print(dt['jsonObject']['zzb']);
        // Sign the user in (or link) with the auto-generated credential
        //await firebaseAuth.signInWithCredential(credential);

      }, timeout: Duration(seconds: 60),

      codeSent: (verificationId, [forceResendingToken])  {

        actualCode  = verificationId;



      }, codeAutoRetrievalTimeout: (String verificationId) {



    }, verificationFailed: ( error) {

    },

    );


  }


  void updateSmsCode(String newSmsCode){

    this.setState(() {
      smsCode = newSmsCode;
    });

  }

  requestNewAccountDriver(String idUser) {
    auth.signOut() ;

    FirebaseFirestore.instance
        .collection("DriverRequestsAccount")
        .doc(idUser)
        .set({

      'yourPhoto' : DataProvider().driverRequest.yourPhoto ,
      'drivingLicense' : DataProvider().driverRequest.drivingLicense ,
      'driverLicense' :DataProvider().driverRequest. driverLicense ,
      'frontCar' : DataProvider().driverRequest.frontCar ,
      'endCar' : DataProvider().driverRequest.endCar ,
      'insideCar' : DataProvider().driverRequest.insideCar ,
      'fullName' : DataProvider().driverRequest.fullName ,
      'typeCar' : DataProvider().driverRequest.typeCar ,
      'modelCar' : DataProvider().driverRequest.modelCar ,
      'colorCar' :DataProvider().driverRequest.colorCar ,
      'phoneNumber' : '+962788051422' ,
      'idUser' : idUser ,
       'numberCar' : DataProvider().driverRequest.numberCar
        }).then((value) {



            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Login(),), (route) => false);

         });

  }

}
