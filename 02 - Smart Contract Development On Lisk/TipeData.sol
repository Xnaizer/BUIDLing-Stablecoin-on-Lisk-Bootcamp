Tipe Data	        Keterangan

uint, int	        Angka (positif dan/atau negatif)
bool	            True / False
address	            Alamat Ethereum
bytes, bytes32	    Data biner
string	            Teks
enum	            Pilihan terbatas (daftar status)
struct	            Gabungan banyak data
array	            Kumpulan data berurutan
mapping	            Pasangan kunci dan nilai
(a, b) (tuple)	    Return value ganda


// uint dan int

// uint = unsigned integer (tidak bisa negatif)
// int = signed integer (bisa positif dan negatif)

// Bisa ditulis spesifik seperti uint8, uint256, int128, dll.


// Kenapa harus pilih ukuran bit?
// Karena:

// Efisiensi gas (biaya eksekusi transaksi di Ethereum)
// Misalnya kamu cuma butuh angka sampai 1000, cukup pakai uint16 atau uint32, jangan uint256, karena lebih kecil → lebih hemat gas.

// Menghemat storage (penyimpanan)
// Bit yang lebih kecil → ukuran penyimpanan lebih kecil.


// Biasanya digunakan di mana?
// uint8 untuk status kecil (misal angka 0 sampai 10)

// uint256 untuk:

// token supply
// jumlah dana dalam aplikasi crowdfunding
// jumlah voting
// waktu (block.timestamp)


// address

// Menyimpan alamat Ethereum (20 bytes).
// Bisa juga address payable kalau ingin menerima ETH.

address owner = msg.sender;
address payable wallet = payable(msg.sender);


// fixed-size bytes1 sampai bytes32

// Ini menyimpan data biner (byte) dengan ukuran yang pasti.
// Misal bytes32 berarti 32 byte = 256 bit.
// Cocok buat menyimpan hash, ID unik, atau data terenkripsi.

// Tipe	        Isi	Keterangan
// bytes	        Data biner	Bisa menyimpan byte apa pun (tidak harus teks)
// string	        Kumpulan karakter teks	Hanya untuk teks, misalnya        "Halo Dunia"

// bytes data = "abc"; 
// Secara teknis: "abc" diubah jadi array byte → [0x61, 0x62, 0x63] (karena 'a' = 0x61, dll).


// array

// number[]
// string[]
// string[3] // isinya ada 3 doang bolehnya


// mapping
// mapping adalah tipe data seperti kamus (dictionary) yang memetakan key → value.

// js : const data = { "Asep": 100, "Budi": 50 };
// go : map[string]uint = { "Asep": 100 }
// sol : mapping(address => uint256) public saldo;
// sol : mapping(address => User) public dataUser;

struct User {
    string nama;
    uint umur;
}

mapping(address => User) public dataUser;

0x123...abc → User(nama: "Asep", umur: 25)
0x456...def → User(nama: "Budi", umur: 30)

// dataUser Itu adalah nama variabel mapping.
// Kamu bisa anggap ini sebagai "daftar data semua user", atau "database mini" yang menyimpan info user berdasarkan alamat wallet mereka.

dataUser[msg.sender].nama = "Asep";
// msg.sender adalah alamat wallet (address) yang sedang memanggil atau mengirim transaksi ke smart contract.

mapping(address => uint256) public saldo;

function deposit() public payable {
    saldo[msg.sender] += msg.value;
}

Kamu kirim ETH ke fungsi deposit().

msg.sender = wallet kamu.

msg.value = jumlah ETH yang kamu kirim.

Maka: saldo kamu akan bertambah di mapping.