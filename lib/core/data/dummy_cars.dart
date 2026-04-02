import '../../features/car/domain/entities/car.dart';

class DummyCars {
  static List<Car> get all => [
    Car(
      id: '1',
      name: 'Maruti Swift VXi',
      brand: 'Maruti',
      price: '650000',
      year: '2022',
      category: 'Hatchback',
      fuelType: 'Petrol',
      transmission: 'Manual',
      description:
          'Single owner. Full service history at authorised centre. '
          'Excellent fuel efficiency, runs smooth. Minor scratches, '
          'mechanically perfect. Original tyres with 60% life remaining.',
      sellerName: 'Rahul Menon',
      sellerId: '',
      imageUrl:
          'https://imgd.aeplcdn.com/1056x594/n/cw/ec/159073/'
          'swift-exterior-right-front-three-quarter-2.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Car(
      id: '2',
      name: 'Hyundai Creta SX',
      brand: 'Hyundai',
      price: '1450000',
      year: '2023',
      category: 'SUV',
      fuelType: 'Diesel',
      transmission: 'Automatic',
      description:
          'Top variant Creta. Panoramic sunroof, ADAS safety suite, '
          '360 camera, Bose audio, ventilated seats. Only 12,000 km '
          'driven. Accident-free. All accessories included.',
      sellerName: 'Priya Nair',
      sellerId: '',
      imageUrl:
          'https://imgd.aeplcdn.com/1056x594/n/cw/ec/106815/'
          'creta-exterior-right-front-three-quarter.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Car(
      id: '3',
      name: 'Tata Nexon EV Max',
      brand: 'Tata',
      price: '1750000',
      year: '2023',
      category: 'SUV',
      fuelType: 'Electric',
      transmission: 'Automatic',
      description:
          '437 km certified range. Home charger included. '
          'Battery warranty valid for 5 more years. Connected car '
          'features, OTA updates. Extremely low running cost.',
      sellerName: 'Admin',
      sellerId: '',
      imageUrl:
          'https://imgd.aeplcdn.com/1056x594/n/cw/ec/141867/'
          'nexon-exterior-right-front-three-quarter-3.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Car(
      id: '4',
      name: 'Honda City ZX CVT',
      brand: 'Honda',
      price: '1250000',
      year: '2022',
      category: 'Sedan',
      fuelType: 'Petrol',
      transmission: 'CVT',
      description:
          'Premium sedan with Honda Sensing ADAS, lane-keep assist, '
          'adaptive cruise. Single owner, company maintained. '
          'Sunroof, wireless charger, 8-inch touchscreen.',
      sellerName: 'Admin',
      sellerId: '',
      imageUrl:
          'https://imgd.aeplcdn.com/1056x594/n/cw/ec/134297/'
          'city-exterior-right-front-three-quarter-3.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    Car(
      id: '5',
      name: 'Toyota Fortuner Legender',
      brand: 'Toyota',
      price: '4200000',
      year: '2023',
      category: 'SUV',
      fuelType: 'Diesel',
      transmission: 'Automatic',
      description:
          '4WD, bi-LED headlamps with auto-levelling, 8-speed AT. '
          'Only 8,000 km driven by a single owner. Dealer maintained. '
          'All original accessories intact.',
      sellerName: 'Arun Kumar',
      sellerId: '',
      imageUrl:
          'https://imgd.aeplcdn.com/1056x594/n/cw/ec/44709/'
          'fortuner-exterior-right-front-three-quarter-3.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Car(
      id: '6',
      name: 'Kia Seltos HTX Plus',
      brand: 'Kia',
      price: '1600000',
      year: '2023',
      category: 'SUV',
      fuelType: 'Petrol',
      transmission: 'AMT',
      description:
          'Panoramic sunroof, Bose 8-speaker audio, 10.25-inch '
          'touchscreen. 360 camera, ADAS. One careful owner. '
          'Service done at Kia service centre.',
      sellerName: 'Deepa Krishnan',
      sellerId: '',
      imageUrl:
          'https://imgd.aeplcdn.com/1056x594/n/cw/ec/35943/'
          'seltos-exterior-right-front-three-quarter-76.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Car(
      id: '7',
      name: 'Mahindra Thar LX',
      brand: 'Mahindra',
      price: '1850000',
      year: '2022',
      category: 'SUV',
      fuelType: 'Diesel',
      transmission: 'Manual',
      description:
          '4x4 hardcore off-roader. Convertible soft-top, '
          'rear-facing jump seats, rock crawl mode. Lightly used, '
          'kept in excellent condition. Accessories worth 1.5L added.',
      sellerName: 'Vishnu Pillai',
      sellerId: '',
      imageUrl:
          'https://imgd.aeplcdn.com/1056x594/n/cw/ec/40087/'
          'thar-exterior-right-front-three-quarter-19.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    Car(
      id: '8',
      name: 'Volkswagen Polo Highline',
      brand: 'Volkswagen',
      price: '750000',
      year: '2021',
      category: 'Hatchback',
      fuelType: 'Petrol',
      transmission: 'Manual',
      description:
          'German engineering at its best. Rock-solid build, '
          'precise handling. Touchscreen infotainment, rear camera. '
          'Well maintained, records available. No major issues.',
      sellerName: 'Sanjay Pillai',
      sellerId: '',
      imageUrl:
          'https://imgd.aeplcdn.com/1056x594/n/cw/ec/2671/'
          'polo-exterior-right-front-three-quarter-3.jpeg',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];
}
