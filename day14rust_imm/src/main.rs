fn iterate(recipes : im::vector::Vector<usize>, elf1 : usize, elf2 : usize) -> (im::vector::Vector<usize>, usize, usize) {
    let sum = recipes[elf1] + recipes[elf2];

    let new_recipes : im::vector::Vector<usize> = if sum >= 10 {
        let mut intermediate = recipes.clone();
        intermediate.push_back(1);
        let mut intermediate2 = intermediate.clone();
        intermediate2.push_back(sum-10);
        intermediate2
    }
    else {
        let mut intermediate = recipes.clone();
        intermediate.push_back(sum);
        intermediate
    };
    
    let l = recipes.len();

    let new_elf1 = (elf1 + recipes[elf1] + 1) % l;
    let new_elf2 = (elf2 + recipes[elf2] + 1) % l;
            
    (new_recipes, new_elf1, new_elf2)
}

fn check_solution(recipes : im::vector::Vector<usize>, seq : &[usize; 6], offset : usize) -> bool {
    let mut i = recipes.len() - 1 - offset;
    let mut s = 5;
        
    loop {
	if recipes[i] == seq[s] {
	    i -= 1;

            if s == 0 {
                break
            }
            
	    s -= 1;
	} else {
	    return false
	}
    }
    true
}

fn main() {
    
    let mut elf1 : usize = 0;
    let mut elf2 : usize = 1;
    let mut recipes : im::vector::Vector<usize> = im::vector![3,7];

    let (recipes2, e1, e2) = iterate(recipes.clone(), elf1, elf2);
    elf1 = e1; elf2 = e2; recipes=recipes2;

    loop {

        
        
   	let (new_recipes, e1, e2) = iterate(recipes.clone(), elf1, elf2);
        elf1 = e1; elf2 = e2;
        
        let l = new_recipes.len();

	if l%100000 == 0 {
	    print!(".")
	}

        if l < 10 {
            continue;
        }
        else {
            let target : [usize; 6] = [6,3,5,0,4,1];

            let found = check_solution(recipes, &target, 0) || check_solution(recipes, &target, 1);
            if found {
                println!("Solution found at len {}", recipes.len());
                break;
            }
        }
        
    }
}
