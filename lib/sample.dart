// using System;
// using System.Collections;
// using System.Configuration;
// using System.Data;
// using System.Linq;
// using System.Web;
// using System.Web.Security;
// using System.Web.UI;
// using System.Web.UI.HtmlControls;
// using System.Web.UI.WebControls;
// using System.Web.UI.WebControls.WebParts;
// using System.Xml.Linq;
// using System.Data.SqlClient;
// using System.Collections.Generic;
// using System.Web.Script.Serialization;

// public partial class Api_frmRiderProfileApi : System.Web.UI.Page
// {
//     private string conn = "Persist Security Info=False;Data Source=184.168.125.10;Initial Catalog=RAMAUTO;User ID=sa;Password=Sri#24211;";
//     protected void Page_Load(object sender, EventArgs e)
//     {
//         string action = Request.QueryString["action"];
//         string jsonInputData;
//         if (action == "I")
//         {
//             using (System.IO.Stream body = Request.InputStream)
//             {
//                 System.Text.Encoding encoding = Request.ContentEncoding;
//                 System.IO.StreamReader reader = new System.IO.StreamReader(body, encoding);
//                 if (Request.ContentLength > 0)
//                 {
//                     jsonInputData = reader.ReadToEnd();

//                     RiderprofileInsert(jsonInputData);
//                 }


//             }
//         }
//         else if (action == "U")
//         {
//             using (System.IO.Stream body = Request.InputStream)
//             {
//                 System.Text.Encoding encoding = Request.ContentEncoding;
//                 System.IO.StreamReader reader = new System.IO.StreamReader(body, encoding);
//                 if (Request.ContentLength > 0)
//                 {
//                     jsonInputData = reader.ReadToEnd();

//                     RiderprofileUpdate(jsonInputData);
//                 }


//             }
//         }
//         else if (Request.QueryString["action"] == "G")
//         {
//             string VehsubTypeid, riderstatus;

//             VehsubTypeid = Request.QueryString["VehsubTypeid"];
//             riderstatus = Request.QueryString["riderstatus"];

            
//             GetRider(VehsubTypeid, riderstatus);
//         }
//         else if (action == "L")
//         {
//             string mobileno;
//             if (Request.QueryString["mobileno"] != "")
//             {

//                 mobileno = Request.QueryString["mobileno"];
                




//                 GetRiderLogin(mobileno);
//             }
//             else
//             {

//                 mobileno = "";
               
//                 Response.Write("{\"status\":\"error\",\"message\":\"No Username Found\"}");
//             }
//         }
//         else
//         {
//             Context.Response.Write("no data");
//         }

//     }
//     public void RiderprofileInsert(string jsonInputData)
//     {
//         try
//         {

//             var serializer = new JavaScriptSerializer();
//             RiderprofileDetRootObject cc = serializer.Deserialize<RiderprofileDetRootObject>(jsonInputData);
//             //list = serializer.Deserialize<RootObject>(jsonInputData);




//             string sql = "";

//             foreach (clsRiderprofile mm in cc.RiderprofileDet)
//             {


//                 string RiderName = mm.RiderName;
//                 string userName = mm.userName;
//                 string password = mm.password;
//                 string MobileNo = mm.MobileNo;
//                 string Vehtypeid = mm.Vehtypeid;
//                 string VehsubTypeid = mm.VehsubTypeid;
//                 string VehNo = mm.VehNo;
//                 string FCDate = mm.FCDate;
//                 string InsDate = mm.InsDate;
//                 string tokenkey = mm.tokenkey;
//                 string Gender = mm.Gender;
//                 string dateofbirth = mm.dateofbirth;
//                 string add1 = mm.add1;
//                 string add2 = mm.add2;
//                 string add3 = mm.add3;
//                 string city = mm.city;
//                 string licenseNo = mm.licenseNo;
//                 string adhaarno = mm.adhaarno;



//                 sql = "    Declare @RiderName		 varchar(50)= '"+ RiderName + "'";
//                 sql += "    Declare @userName		 varchar(50)='"+ userName + "'";
//                 sql += "    Declare @password		 varchar(50)='"+ password + "'";
//                 sql += "    Declare @MobileNo		 varchar(12)='"+ MobileNo + "'";
//                 sql += "    Declare @Vehtypeid      bigint='"+ Vehtypeid + "'";
//                 sql += "    Declare @VehsubTypeid	 bigint='"+ VehsubTypeid + "'";
//                 sql += "    Declare @VehNo			 varchar(20)='"+ VehNo + "'";
//                 sql += "    Declare @FCDate		 smalldatetime='"+ FCDate + "'";
//                 sql += "    Declare @InsDate        smalldatetime='"+ InsDate + "'";
//                 sql += "    Declare @tokenkey        varchar(max)='" + tokenkey + "'";
//                 sql += "    Declare @Gender        varchar(1)='" + Gender + "'";
//                 sql += "    Declare @dateofbirth       smalldatetime ='" + dateofbirth + "'";
//                 sql += "    Declare @add1        varchar(50)='" + add1 + "'";
//                 sql += "    Declare @add2        varchar(50)='" + add1 + "'";
//                 sql += "    Declare @add3        varchar(50)='" + add1 + "'";
//                 sql += "    Declare @city        varchar(50)='" + city + "'";
//                 sql += "    Declare @licenseNo        varchar(20)='" + licenseNo + "'";
//                 sql += "    Declare @adhaarno        varchar(20)='" + adhaarno + "'";
//                 sql += "    insert into RiderProfile(RiderName,userName,password,MobileNo,Vehtypeid,VehsubTypeid,VehNo,FCDate,InsDate,tokenkey,Gender,dateofbirth,add1,add2,add3,city,licenseNo,adhaarno)";
//                 sql += "    values( @RiderName, @userName, @password, @MobileNo, @Vehtypeid, @VehsubTypeid, @VehNo, @FCDate, @InsDate,@tokenkey,@Gender,@dateofbirth,@add1,@add2,@add3,@city,@licenseNo,@adhaarno)";




//             }

//             using (SqlConnection connection = new SqlConnection(conn))
//             {
//                 if (sql != "")
//                 {

//                     connection.Open();
//                     SqlCommand command = new SqlCommand(sql, connection);
//                     command.ExecuteNonQuery();
//                     connection.Close();
//                 }

//             }
//             Response.Write("{\"status\":\"success\",\"message\":\"Insert Successfully\"}");
//         }
//         catch (Exception ex)
//         {
//             Context.Response.Write("Error: " + ex.Message);
//         }
//     }
//     public void RiderprofileUpdate(string jsonInputData)
//     {
//         try
//         {

//             var serializer = new JavaScriptSerializer();
//             RiderprofileDetRootObject cc = serializer.Deserialize<RiderprofileDetRootObject>(jsonInputData);
//             //list = serializer.Deserialize<RootObject>(jsonInputData);




//             string sql = "";

//             foreach (clsRiderprofileupdate mm in cc.updateriderpro)
//             {


//                 string Riderid = mm.Riderid;
//                 string FromLatLong = mm.FromLatLong;
              
//                 string riderstatus = mm.riderstatus;
//                 string timestamp = mm.timestamp;


//                 sql = "update RiderProfile set FromLatLong='" + FromLatLong + "',";
//                 sql += "riderstatus='" + riderstatus + "',timestamp='" + timestamp + "' where Riderid='" + Riderid + "'";






//             }

//             using (SqlConnection connection = new SqlConnection(conn))
//             {
//                 if (sql != "")
//                 {

//                     connection.Open();
//                     SqlCommand command = new SqlCommand(sql, connection);
//                     command.ExecuteNonQuery();
//                     connection.Close();
//                 }

//             }
//             Response.Write("{\"status\":\"success\",\"message\":\"Update Successfully\"}");
//         }
//         catch (Exception ex)
//         {
//             Context.Response.Write("Error: " + ex.Message);
//         }
//     }
//     public void GetRiderLogin(string mobileno)
//     {
//         SqlConnection conmaster = new SqlConnection();
//         SqlCommand cmd = new SqlCommand();
//         SqlDataAdapter da = new SqlDataAdapter();
//         conmaster = new SqlConnection(conn);
//         conmaster.Open();

//         string sql;


//         sql = "    select Riderid,RiderName,userName,password,MobileNo,Vehtypeid,VehsubTypeid,VehNo,FCDate,InsDate,tokenkey,Gender,dateofbirth,add1,add2,add3,city,licenseNo,adhaarno from RiderProfile";
//         sql += "    where mobileno ='" + mobileno + "'";


//         da = new SqlDataAdapter(sql, conmaster);
//         DataTable dt = new DataTable();
//         da.Fill(dt);
//         List<clsRiderLogin> lstclsRiderpro = new List<clsRiderLogin>();
//         conmaster.Close();

//         if (dt.Rows.Count == 0)

//         {
//             Response.Write("{\"status\":\"error\",\"message\":\"No Username Found\"}");
//         }
//         else
//         {
//             for (int i = 0; i <= dt.Rows.Count - 1; i++)
//             {
//                 clsRiderLogin clsriderpro = new clsRiderLogin();

//                 clsriderpro.Riderid = Convert.ToString(dt.Rows[i]["Riderid"]);
//                 clsriderpro.RiderName = Convert.ToString(dt.Rows[i]["RiderName"]);
//                 clsriderpro.userName = Convert.ToString(dt.Rows[i]["userName"]);
//                 clsriderpro.password = Convert.ToString(dt.Rows[i]["password"]);
//                 clsriderpro.MobileNo = Convert.ToString(dt.Rows[i]["MobileNo"]);
//                 clsriderpro.Vehtypeid = Convert.ToString(dt.Rows[i]["Vehtypeid"]);
//                 clsriderpro.VehsubTypeid = Convert.ToString(dt.Rows[i]["VehsubTypeid"]);
//                 clsriderpro.VehNo = Convert.ToString(dt.Rows[i]["VehNo"]);
//                 clsriderpro.FCDate = Convert.ToString(dt.Rows[i]["FCDate"]);
//                 clsriderpro.InsDate = Convert.ToString(dt.Rows[i]["InsDate"]);
//                 clsriderpro.tokenkey = Convert.ToString(dt.Rows[i]["tokenkey"]);
               



//                 lstclsRiderpro.Add(clsriderpro);

//             }
//             JavaScriptSerializer js = new JavaScriptSerializer();
//             Context.Response.Write("{\"status\":\"success\",\"data\":");
//             Context.Response.Write(js.Serialize(lstclsRiderpro));
//             Context.Response.Write("}");
//         }
//     }

//     public void GetRider(string VehsubTypeid, string riderstatus)
//     {
//         SqlConnection conmaster = new SqlConnection();
//         SqlCommand cmd = new SqlCommand();
//         SqlDataAdapter da = new SqlDataAdapter();
//         conmaster = new SqlConnection(conn);
//         conmaster.Open();

//         string sql;

//         sql = "    select RiderName,MobileNo,VehsubTypeid,riderstatus,FromLatLong,tokenkey from RiderProfile ";
//         sql += "    where VehsubTypeid='"+ VehsubTypeid + "' and riderstatus='"+ riderstatus + "'";



//         da = new SqlDataAdapter(sql, conmaster);
//         DataTable dt = new DataTable();
//         da.Fill(dt);
//         List<clsriderget> lstclsRiderpro = new List<clsriderget>();
//         conmaster.Close();

//         if (dt.Rows.Count == 0)

//         {
//             Response.Write("{\"status\":\"error\",\"message\":\"No Username Found\"}");
//         }
//         else
//         {
//             for (int i = 0; i <= dt.Rows.Count - 1; i++)
//             {
//                 clsriderget clsriderget = new clsriderget();



//                 clsriderget.RiderName = Convert.ToString(dt.Rows[i]["RiderName"]);
//                 clsriderget.MobileNo = Convert.ToString(dt.Rows[i]["MobileNo"]);
//                 clsriderget.VehsubTypeid = Convert.ToString(dt.Rows[i]["VehsubTypeid"]);
//                 clsriderget.riderstatus = Convert.ToString(dt.Rows[i]["riderstatus"]);
//                 clsriderget.FromLatLong = Convert.ToString(dt.Rows[i]["FromLatLong"]);
               
//                 clsriderget.tokenkey = Convert.ToString(dt.Rows[i]["tokenkey"]);




//                 lstclsRiderpro.Add(clsriderget);

//             }
//             JavaScriptSerializer js = new JavaScriptSerializer();
//             Context.Response.Write("{\"status\":\"success\",\"data\":");
//             Context.Response.Write(js.Serialize(lstclsRiderpro));
//             Context.Response.Write("}");
//         }
//     }
// }
// public class clsRiderprofile
// {
//     public string RiderName { get; set; }
//     public string userName { get; set; }
//     public string password { get; set; }
//     public string MobileNo { get; set; }
//     public string Vehtypeid { get; set; }
//     public string VehsubTypeid { get; set; }
//     public string VehNo { get; set; }
//     public string FCDate { get; set; }
//     public string InsDate { get; set; }
//     public string tokenkey { get; set; }
//     public string Gender      { get; set; }
//     public string dateofbirth { get; set; }
//     public string add1        { get; set; }
//     public string add2        { get; set; }
//     public string add3        { get; set; }
//     public string city        { get; set; }
//     public string licenseNo   { get; set; }
//     public string adhaarno     { get; set; }
// }
// public class clsRiderprofileupdate
// {
//     public string Riderid { get; set; }
//     public string FromLatLong { get; set; }
    
//     public string riderstatus { get; set; }
//     public string timestamp { get; set; }
   

// }

// public class clsRiderLogin
// {

//     public string Riderid { get; set; }
//     public string RiderName { get; set; }
//     public string userName { get; set; }
//     public string password { get; set; }
//     public string MobileNo { get; set; }
//     public string Vehtypeid { get; set; }
//     public string VehsubTypeid { get; set; }
//     public string VehNo { get; set; }
//     public string FCDate { get; set; }
//     public string InsDate { get; set; }
//     public string tokenkey { get; set; }



// }
// public class clsriderget
// {
//     public string RiderName { get; set; }
//     public string MobileNo { get; set; }
//     public string VehsubTypeid { get; set; }
//     public string riderstatus { get; set; }
//     public string FromLatLong  { get; set; }
   
//     public string tokenkey { get; set; }
// }
// public class RiderprofileDetRootObject
// {
//     public List<clsRiderprofile> RiderprofileDet { get; set; }
//     public List<clsRiderprofileupdate> updateriderpro { get; set; }
// }
