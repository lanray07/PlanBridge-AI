import Foundation

public enum DemoData {
    public static func archive(now: Date = Date()) -> PlanArchive {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier:"Europe/London")!
        let day = calendar.startOfDay(for: now)
        func at(_ hour: Int, _ minute: Int = 0, day offset: Int = 0) -> Date {
            calendar.date(byAdding: .minute, value: hour * 60 + minute + offset * 1440, to: day)!
        }
        let trip = Trip(name:"Manchester, for the evening",destination:"Manchester",start:at(17),end:at(23))
        let paris = Trip(name:"A few days in Paris",destination:"Paris",start:at(9,day:6),end:at(18,day:10))
        var result = PlanArchive(); result.trips = [trip,paris]
        result.plans = [
            PlanItem(title:"Morning focus",kind:.meeting,start:at(9),end:at(10),location:PlanLocation(name:"Home",city:"London"),source:.demo),
            PlanItem(title:"Design catch-up",kind:.meeting,start:at(11),end:at(11,45),location:PlanLocation(name:"Studio",city:"London"),source:.demo),
            PlanItem(title:"London → Manchester",kind:.train,start:at(17,30),end:at(19,42),location:PlanLocation(name:"London Euston",city:"London"),destination:PlanLocation(name:"Manchester Piccadilly",city:"Manchester"),source:.demo,tripID:trip.id),
            PlanItem(title:"Dinner at The French",kind:.restaurant,start:at(19,30),end:at(21),location:PlanLocation(name:"The French",city:"Manchester"),source:.demo,tripID:trip.id),
            PlanItem(title:"The Midland",kind:.hotel,start:at(15),end:at(11,day:1),location:PlanLocation(name:"The Midland",city:"Manchester"),source:.demo,tripID:trip.id),
            PlanItem(title:"Evening reading",kind:.event,start:at(22),end:at(22,30),source:.demo),
            PlanItem(title:"London → Paris",kind:.flight,start:at(9,day:6),end:at(10,20,day:6),arrivalTimeZoneID:"Europe/Paris",location:PlanLocation(name:"Heathrow",city:"London"),destination:PlanLocation(name:"Charles de Gaulle",city:"Paris"),source:.demo,tripID:paris.id),
            PlanItem(title:"Hôtel des Arts",kind:.hotel,start:at(14,day:6),end:at(10,day:10),timeZoneID:"Europe/Paris",location:PlanLocation(name:"Montmartre",city:"Paris"),source:.demo,tripID:paris.id)
        ]
        return result
    }
}
