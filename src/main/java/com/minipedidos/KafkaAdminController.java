import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.*;

@Component
@RestController
@RequestMapping("/api/admin/kafka")
public class KafkaAdminController {

    @GetMapping("/topicos")
    public String[] listarTopicos() {
        return new String[]{"test"};
    }
}