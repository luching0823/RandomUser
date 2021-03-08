//
//  ViewController.swift
//  RandomUser
//
//  Created by 廖昱晴 on 2021/3/8.
//

import UIKit

struct User {
    
    var name: String?
    var email: String?
    var number: String?
    var image: String?
    
}

//解析JSON要訣：1.遇到字典要新增struct 2.只新增需要的資料key 3.變數名稱要跟資料key一樣

struct AllData: Decodable {
    
    var results: [SingleData?]
}

struct SingleData: Decodable {
    
    var name: Name?
    var email: String?
    var phone: String?
    var picture: Picture?
    
}

struct Name: Decodable {
    
    var first: String?
    var last: String?
    
}

struct Picture: Decodable {
    
    var large: String?
    
}

class ViewController: UIViewController {
    
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var userName: UILabel!
    
    var infoTableViewController: TableViewController?
    var urlSession = URLSession(configuration: .default) //產生URLSession
    var isDownloading = false
    let apiAddress = "https://randomuser.me/api/"
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //透過segue抓到tableViewController，以便設定phone跟email
        if segue.identifier == "moreInfo" {
            infoTableViewController = segue.destination as? TableViewController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        let user = User(name: "Pulin", email: "pulin@gmail.com", number: "0912345678", image: "http://picture.me")
//        settingInfo(user: user)
        downloadInfo(withAddress: apiAddress)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userImage.layer.cornerRadius = userImage.frame.size.width / 2 //圖片圓角設為圖片寬度的一半，在畫面顯示完成實在執行，因為這時已經確定畫面大小，viewDidLoad還沒確定
        userImage.clipsToBounds = true //修剪圖片成圓形
        
    }
    
    @IBAction func makeNewUser(_ sender: UIBarButtonItem) {
        if isDownloading == false { //沒有在下載才能重新下載
            downloadInfo(withAddress: apiAddress)
        }
    }
    
    func settingInfo(user: User) { //將資料放到對應label
        userName.text = user.name
        infoTableViewController?.phone.text = user.number
        infoTableViewController?.email.text = user.email
        if let imageAddress = user.image {
            if let url = URL(string: imageAddress) {
                let task = urlSession.downloadTask(with: url, completionHandler: { (url, response, error) in
                    if error != nil {
                        DispatchQueue.main.async { //URLSession是共時佇列，跳出提示框要用主佇列顯示
                            self.popAlert(withTitle: "Sorry")
                        }
                        self.isDownloading = false
                        return
                    }
                    if let okURL = url {
                        do {
                            let downloadImage = UIImage(data: try Data(contentsOf: okURL))
                            DispatchQueue.main.async { //顯示下載好的圖片
                                self.userImage.image = downloadImage
                                self.isDownloading = false
                            }
                        } catch {
                            DispatchQueue.main.async {
                                self.popAlert(withTitle: "Sorry")
                            }
                            self.isDownloading = false
                        }
                    } else {
                        self.isDownloading = false
                    }
                })
                task.resume()
                self.isDownloading = true
            } else {
                self.isDownloading = false
            }
            
        } else {
            self.isDownloading = false
        }
    }
    
    func downloadInfo(withAddress webAddress: String) { //下載資料
        if let url = URL(string: webAddress) {
            let task = urlSession.dataTask(with: url, completionHandler: { (data, response, error) in
                if error != nil {
                    let errorCode = (error! as NSError).code
                    if errorCode == -1009 { //無連接網路
                        DispatchQueue.main.async {
                            self.popAlert(withTitle: "No Internet Connection")
                        }
                        print("No Internet Connection")
                    } else {
                        DispatchQueue.main.async {
                            self.popAlert(withTitle: "Something is wrong")
                        }
                        print("Something is wrong")
                    }
                    self.isDownloading = false
                    return
                }
                if let loadedData = data { //順利下載
                    do {
//                        let json = try JSONSerialization.jsonObject(with: loadedData, options: [])
//                        DispatchQueue.main.async { //資料已經下載完
//                            self.parseJson(json: json)
//                        }
                        let okData = try JSONDecoder().decode(AllData.self, from: loadedData) //解析json資料
                        let firstName = okData.results[0]?.name?.first
                        let lastName = okData.results[0]?.name?.last
                        let fullName: String? = {
                            guard let okFirstName = firstName, let okLastName = lastName else {return nil}
                            return okFirstName + " " + okLastName
                        }()
                        
                        let email = okData.results[0]?.email
                        let phone = okData.results[0]?.phone
                        let picture = okData.results[0]?.picture?.large
                        let aUser = User(name: fullName, email: email, number: phone, image: picture)
                        DispatchQueue.main.async {
                            self.settingInfo(user: aUser)
                        }
                    } catch {
//                        DispatchQueue.main.async {
//                            self.popAlert(withTitle: "Something is wrong")
//                        }
                        DispatchQueue.main.async {
                            self.popAlert(withTitle: "Sorry")
                        }
                        self.isDownloading = false
                    }
                } else {
                    self.isDownloading = false
                }
            })
            task.resume() //開始下載
            isDownloading = true
        }
        
    }
    
    func popAlert(withTitle title: String) {
        let alert = UIAlertController(title: title, message: "Please try again later", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
//    func parseJson(json: Any) {
//        if let okJson = json as? [String: Any] {
//            if let infoArray = okJson["results"] as? [[String: Any]] {
//                let infoDictionary = infoArray[0]
//                let loadedName = userFullName(nameDictionary: infoDictionary["name"])
//                let loadedEmail = infoDictionary["email"] as? String
//                let loadedPhone = infoDictionary["phone"] as? String
//                let imageDictionary = infoDictionary["picture"] as? [String: String]
//                let loadedImageAddress = imageDictionary?["large"]
//                let loadedUser = User(name: loadedName, email: loadedEmail, number: loadedPhone, image: loadedImageAddress)
//                settingInfo(user: loadedUser)
//            }
//        }
//    }
//
//    func userFullName(nameDictionary: Any?) -> String? {
//        if let okDictionary = nameDictionary as? [String: String] {
//            let firstName = okDictionary["first"] ?? ""
//            let lastName = okDictionary["last"] ?? ""
//
//            return firstName + " " + lastName
//        } else {
//            return nil
//        }
//    }

}

